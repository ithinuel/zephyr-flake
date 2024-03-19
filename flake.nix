{
  description = "Zephyr dev environment";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";

    sdk.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/zephyr-sdk-0.16.5-1_linux-x86_64_minimal.tar.xz";
    sdk.flake = false;

    toolchain_x86_64.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_x86_64-zephyr-elf.tar.xz";
    toolchain_x86_64.flake = false;

    toolchain_arm.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz";
    toolchain_arm.flake = false;

    toolchain_aarch64.url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.5-1/toolchain_linux-x86_64_aarch64-zephyr-elf.tar.xz";
    toolchain_aarch64.flake = false;
  };

  outputs = inputs@{ nixpkgs, flake-utils, ... }:
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

            for src in $srcs; do
                cp --no-preserve=mode -r $src/* $out
            done

            chmod +x $out/bin/*

            runHook postInstall
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
                zephyr-sdk
                cmake
                python311Packages.west
            ];
            shellHook = ''
            export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
            '';
        };
      });
}

