let
  selected_archs = [ "arm-zephyr-eabi" "aarch64-zephyr-elf" ];
  version = "0.17.4";
  config = {
    host = [
      "linux-aarch64"
      "macos-aarch64"
    ];
    toolchain = [
      "aarch64-zephyr-elf"
      "arm-zephyr-eabi"
      #"x86_64-zephyr-elf"
    ];
  };
  nix-system2zephyr = {
    aarch64-linux = "linux-aarch64";
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
      flake-utils.url = "github:numtide/flake-utils";
      git-hooks.url = "github:cachix/git-hooks.nix";
      git-hooks.inputs.nixpkgs.follows = "nixpkgs";
      nixpkgs.url = "nixpkgs/nixos-25.05";
      nixpkgs_python38.url = "nixpkgs/nixos-23.11";
      pyproject-nix = {
        url = "github:pyproject-nix/pyproject.nix";
        inputs.nixpkgs.follows = "nixpkgs";
      };
      zephyr = {
        url = "github:zephyrproject-rtos/zephyr";
        flake = false;
      };
    };

  outputs = inputs@{ nixpkgs, nixpkgs_python38, flake-utils, git-hooks, pyproject-nix, zephyr, ... }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs_python38.legacyPackages.${system}) python38;

        pkgs = nixpkgs.legacyPackages.${system};
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
        # add a few packages not already present in nixpkgs.
        python = pkgs.python3.override {
          packageOverrides = final: prev: {
            gitlint-core = final.buildPythonPackage rec {
              pname = "gitlint_core";
              version = "0.19.1";
              format = "pyproject";
              src = pkgs.fetchPypi {
                inherit pname version;
                sha256 = "sha256-e/l3sD/1gWJKngP2XruFAswS36o+ktI+iytUu9qimZI=";
              };
              build-system = [
                final.hatchling
                final.hatch-vcs
              ];
              dependencies = with final; [ arrow click sh ];

              doCheck = false;
            };
            sphinx-lint = final.buildPythonPackage rec {
              pname = "sphinx_lint";
              version = "1.0.0";
              format = "pyproject";
              src = pkgs.fetchPypi {
                inherit pname version;
                sha256 = "sha256-bq/bRBcs5Sb0Bb82xxPrJG8TQOwtZn5ymOJIftdt7NI=";
              };
              doCheck = false;
              build-system = [ final.hatchling final.hatch-vcs ];
              dependencies = [ final.polib final.regex ];
            };
            vermin = final.buildPythonPackage rec {
              pname = "vermin";
              version = "1.6.0";
              src = pkgs.fetchPypi {
                inherit pname version;
                sha256 = "sha256-YmbKAvVdHCqhiaYQAXwTLrLRk08J5yqVWx6zgg7m1O8=";
              };
              doCheck = false;
            };
            # used by docs
            sphinx-last-updated-by-git = final.buildPythonPackage rec {
              pname = "sphinx_last_updated_by_git";
              version = "0.3.8";
              src = pkgs.fetchPypi {
                inherit pname version;
                sha256 = "sha256-wUUBH0YJ2EGAW2mpMACZ/AL+2PW7nlvO932Xrql7d2E=";
              };
              doCheck = false;
            };
            coverxygen = final.buildPythonPackage rec {
              pname = "coverxygen";
              version = "1.8.1";
              src = pkgs.fetchPypi {
                inherit pname version;
                sha256 = "sha256-0cL2Vp6N+II64xOx94duiP8gtDcsbQLwTFH7XcQkV28=";
              };
              doCheck = false;
            };
          };
        };
        project' = pyproject-nix.lib.project.loadRequirementsTxt {
          requirements = "${zephyr}/scripts/requirements.txt";
        };
        project =
          let
            excludedPackages = [ "clang-format" "gcovr" "spsdk" ];
            filterOutDeps = builtins.filter (x: !builtins.elem x.name excludedPackages);
          in
          project' // {
            dependencies = project'.dependencies // {
              dependencies = filterOutDeps project'.dependencies.dependencies;
            };
          };
        env = python.withPackages (pyproject-nix.lib.renderers.withPackages { inherit python project; });

        doc_project = pyproject-nix.lib.project.loadRequirementsTxt {
          requirements = "${zephyr}/doc/requirements.txt";
        };
        doc_env = python.withPackages (doc_project.renderers.withPackages { inherit python; });
      in
      rec {
        formatter = pkgs.nixpkgs-fmt;
        checks = {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              convco.enable = true;
              gitlint.enable = true;
              markdownlint.enable = true;
              markdownlint.settings.configuration = {
                MD013 = {
                  line_length = 100;
                  code_blocks = false;
                };
              };
            };
          };
        };
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
            [ packages.zephyr-sdk env ];
          env = {
            ZEPHYR_SDK_INSTALL_DIR = "${packages.zephyr-sdk}";
            ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
          };
        };
        devShells.doc = pkgs.mkShell {
          buildInputs = with pkgs; [ doxygen texliveFull graphviz imagemagick doc_env ];
        };
      }
    ));
}
