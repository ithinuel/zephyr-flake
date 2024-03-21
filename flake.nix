{
  description = "Zephyr dev environment";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";

    x86_64-linux_sdk.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/zephyr-sdk-0.16.5-1_linux-x86_64_minimal.tar.xz";
    x86_64-linux_sdk.flake = false;
    x86_64-linux_toolchain_x86_64.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_x86_64-zephyr-elf.tar.xz";
    x86_64-linux_toolchain_x86_64.flake = false;
    x86_64-linux_toolchain_arm.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz";
    x86_64-linux_toolchain_arm.flake = false;
    x86_64-linux_toolchain_aarch64.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_aarch64-zephyr-elf.tar.xz";
    x86_64-linux_toolchain_aarch64.flake = false;

    aarch64-linux_sdk.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/zephyr-sdk-0.16.5-1_linux-aarch64_minimal.tar.xz";
    aarch64-linux_sdk.flake = false;
    aarch64-linux_toolchain_x86_64.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-aarch64_x86_64-zephyr-elf.tar.xz";
    aarch64-linux_toolchain_x86_64.flake = false;
    aarch64-linux_toolchain_arm.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-aarch64_arm-zephyr-eabi.tar.xz";
    aarch64-linux_toolchain_arm.flake = false;
    aarch64-linux_toolchain_aarch64.url =
      "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-aarch64_aarch64-zephyr-elf.tar.xz";
    aarch64-linux_toolchain_aarch64.flake = false;

    zephyr.url = "github:zephyrproject-rtos/zephyr";
    zephyr.flake = false;

    pyocd.url = "github:pyocd/pyocd";
    pyocd.flake = false;
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, dream2nix, mach-nix, ... }:
    flake-utils.lib.simpleFlake {
      inherit self nixpkgs;
      name = "zephyr-flake";
      shell = { pkgs }:
        let
          target_archs = [ "x86_64" "arm" "aarch64" ];

          zephyr-sdk = pkgs.stdenvNoCC.mkDerivation
            (import ./zephyr-sdk.nix { inherit pkgs inputs target_archs; });

          pythonEnv = (dream2nix.lib.evalModules {
            packageSets.nixpkgs = pkgs;
            modules = [
              ({ config, lib, dream2nix, ... }: {
                imports = [ dream2nix.modules.dream2nix.pip ];

                deps = { nixpkgs, ... }: { python = nixpkgs.python311; };

                name = "zephyr-scripts";
                version = "0.0.1";

                pip.requirementsFiles =
                  [ "${inputs.zephyr}/scripts/requirements.txt" ];
                pip.requirementsList = [ "click" "cryptography" ];
                pip.flattenDependencies = true;
              })
              {
                paths.projectRoot = ./.;
                paths.package = ./.;
              }
            ];
          }).devShell;
        in pkgs.mkShell {
          inputsFrom = [ pythonEnv ];
          buildInputs = with pkgs; [ zephyr-sdk cmake ninja gperf ];
          shellHook = ''
            export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
            export PATH="$PATH:${zephyr-sdk}/sysroots/x86_64-pokysdk-linux/usr/bin"
            for src in ${builtins.concatStringsSep " " target_archs}; do
              export PATH="$PATH:${zephyr-sdk}/$src-zephyr-eabi/bin"
            done
          '';
        };
    };
}

