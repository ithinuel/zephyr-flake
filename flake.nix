{
  description = "Zephyr dev environment";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix.url = "mach-nix";

    sdk.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/zephyr-sdk-0.16.5-1_linux-x86_64_minimal.tar.xz";
    sdk.flake = false;

    toolchain_x86_64.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_x86_64-zephyr-elf.tar.xz";
    toolchain_x86_64.flake = false;

    toolchain_arm.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz";
    toolchain_arm.flake = false;

    toolchain_aarch64.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_aarch64-zephyr-elf.tar.xz";
    toolchain_aarch64.flake = false;
  };

  outputs = inputs@{ nixpkgs, flake-utils, mach-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # build hosttools (aka sdk?)
        zephyr-sdk = pkgs.stdenv.mkDerivation {
          name = "zephyr-sdk";
          version = "0.16.5-1";
          srcs = map (arch: inputs."toolchain_${arch}") [ "x86_64" "arm" "aarch64" ];
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            cmake
            which
            python38
          ];
          phases = [ "installPhase" "fixupPhase" ];
          installPhase = ''
            runHook preInstall

            mkdir -p $out
            ${inputs.sdk}/zephyr-sdk-x86_64-hosttools-standalone-0.9.sh -d $out -y
            cp -r ${inputs.sdk}/{cmake,sdk_*} $out

            addAutoPatchelfSearchPath $out/sysroots/x86_64-pokysdk-linux/lib

            for src in $srcs; do
                arch=$(basename $(find $src -maxdepth 1 -name "*zephyr*"))
                mkdir -p $out/$arch
                cp -r $src/* $out/$arch
                addAutoPatchelfSearchPath $out/$arch/lib
                addAutoPatchelfSearchPath $out/$arch/libexec
            done

            runHook postInstall

            # after nixos’ fixup, revert to the interpreter provided with the package
            postFixupHooks+=('
                echo "Restoring interpreters…"
                for bin in $(ls $out/sysroots/x86_64-pokysdk-linux/usr/bin); do
                    patchelf --set-interpreter $out/sysroots/x86_64-pokysdk-linux/lib/ld-linux-x86-64.so.2 \
                        $out/sysroots/x86_64-pokysdk-linux/usr/bin/$bin
                done
            ')
          '';
        };

        # not so great because we need to copy the requirement files here to have them accessible to
        # the flake but that will do for now
        requirementsFileList =  map (name: ./requirements-${name}.txt)
            [ "base" "build-test" "run-test" "compliance" ]; # "extras"
        allRequirements = pkgs.lib.concatStrings (map (x: builtins.readFile x) requirementsFileList) + ''
        # extra python requirements
        click
        cryptography
        '';
        pythonEnv = mach-nix.lib.${system}.mkPython { requirements = allRequirements; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zephyr-sdk
            cmake
            ninja
            pythonEnv
          ];
          shellHook = ''
          export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
          '';
        };
      });
}

