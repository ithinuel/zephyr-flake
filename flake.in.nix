let
  selected_archs = [ "arm-zephyr-eabi" "aarch64-zephyr-elf" ];
  version = "0.16.8";
  config = {
    host = [ "linux-x86_64" "linux-aarch64" "macos-x86_64" "macos-aarch64" ];
    toolchain = [
      "aarch64-zephyr-elf"
      #"arc-zephyr-elf"
      #"arc64-zephyr-elf"
      "arm-zephyr-eabi"
      #"microblazeel-zephyr-elf"
      #"mips-zephyr-elf"
      #"nios2-zephyr-elf"
      #"riscv64-zephyr-elf"
      #"sparc-zephyr-elf"
      #"x86_64-zephyr-elf"
      #"xtensa-dc233c_zephyr-elf"
      #"xtensa-espressif_esp32_zephyr-elf"
      #"xtensa-espressif_esp32s2_zephyr-elf"
      #"xtensa-espressif_esp32s3_zephyr-elf"
      #"xtensa-intel_ace15_mtpm_zephyr-elf"
      #"xtensa-intel_tgl_adsp_zephyr-elf"
      #"xtensa-mtk_mt8195_adsp_zephyr-elf"
      #"xtensa-nxp_imx_adsp_zephyr-elf"
      #"xtensa-nxp_imx8m_adsp_zephyr-elf"
      #"xtensa-nxp_imx8ulp_adsp_zephyr-elf"
      #"xtensa-nxp_rt500_adsp_zephyr-elf"
      #"xtensa-nxp_rt600_adsp_zephyr-elf"
      #"xtensa-sample_controller_zephyr-elf"
    ];
  };
  nix-system2zephyr = {
    x86_64-linux = "linux-x86_64";
    aarch64-linux = "linux-aarch64";
    x86_64-darwin = "macos-aarch64";
    aarch64-darwin = "macos-aarch64";
  };
  cartesianProductOfSets =
    attrsOfLists:
    builtins.foldl'
      (listOfAttrs: attrName:
      builtins.concatMap (attrs: map (listValue: attrs // { ${attrName} = listValue; }) attrsOfLists.${attrName}) listOfAttrs
      ) [{ }]
      (builtins.attrNames attrsOfLists);
  toolchains = cartesianProductOfSets config;
in
{
  description = "The real nix file";

  inputs =
    let
      genSdkInputs = host: {
        "sdk_${host}" = {
          url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/zephyr-sdk-${version}_${host}_minimal.tar.xz";
          flake = false;
        };
      };
      genToolchainInputs = { host, toolchain }: {
        "toolchain_${host}_${toolchain}" = {
          url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/toolchain_${host}_${toolchain}.tar.xz";
          flake = false;
        };
      };
      toolchainsInputs = builtins.foldl' (acc: elem: elem // acc) { } (builtins.map genToolchainInputs toolchains);
      sdkInputs = builtins.foldl' (acc: elem: elem // acc) { } (builtins.map genSdkInputs config.host);
    in
    sdkInputs //
    toolchainsInputs // {
      nixpkgs.url = "nixpkgs/nixos-24.05";
      nixpkgs_python38.url = "nixpkgs/nixos-23.11";
      flake-utils.url = "github:numtide/flake-utils";
    };

  outputs = inputs@{ self, nixpkgs, nixpkgs_python38, flake-utils, ... }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python38 = nixpkgs_python38.legacyPackages.${system}.python38;
        host = nix-system2zephyr.${system};
        arch2toolchain = arch: "toolchain_${arch}";
        genToolchainPackages = arch: {
          "${arch2toolchain arch}" = pkgs.stdenv.mkDerivation {
            pname = arch2toolchain arch;
            inherit version;

            #nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;

            src = inputs."toolchain_${host}_${arch}";

            enableParallelBuilding = true;
            dontUnpack = true;
            dontConfigure = true;
            dontBuild = true;
            dontPatchELF = true;
            dontStrip = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out;
              echo "Extracting toolchain: ${arch}"
              tar -C $out -xf $src --strip-components=1

              runHook postInstall
            '';

            preFixup = ''
              find $out -type f | while read f; do
                patchelf "$f" > /dev/null 2>&1 || continue
                patchelf --set-interpreter $(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker) "$f" || true
                patchelf --set-rpath ${pkgs.lib.makeLibraryPath [ "$out" pkgs.stdenv.cc.cc python38 ]} "$f" || true
              done
            '';

          };
        };
      in
      rec {
        formatter = pkgs.nixpkgs-fmt;
        packages = rec {
          default = zephyr-sdk;
          zephyr-sdk = pkgs.stdenv.mkDerivation {
            pname = "zephyr-sdk";
            inherit version;

            enableParallelBuilding = true;
            dontUnpack = true;

            buildInputs = builtins.map (arch: packages.${arch2toolchain arch}) selected_archs;

            src = inputs."sdk_${host}";
            installPhase = ''
              mkdir -p $out
              tar -C $out -xf $src --strip-components=1
              echo "Linking toolchains to this sdk"
            '' + pkgs.lib.strings.concatMapStringsSep "\n"
              (arch: "ln -s ${ packages.${arch2toolchain arch}.outPath } $out/${arch}")
              selected_archs;
          };
        } // (pkgs.lib.foldl (acc: arch: (genToolchainPackages arch) // acc) { } selected_archs);

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ cmake ninja gperf dtc qemu thrift python312 python312Packages.autopep8 ] ++
            (builtins.map (arch: packages.${arch2toolchain arch}) selected_archs) ++
            [ packages.zephyr-sdk ];
          shellHook = ''
            export ZEPHYR_SDK_INSTALL_DIR=${packages.zephyr-sdk}
            export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
          '';
        };
      }
    ));
}
