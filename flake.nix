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
        version = "0.16.5-1";
        # build hosttools (aka sdk?)
        hosttools = pkgs.stdenv.mkDerivation {
          inherit version;
          name = "hosttools";
          src = inputs.sdk;
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
            $src/zephyr-sdk-x86_64-hosttools-standalone-0.9.sh -d $out -y
            runHook postInstall
          '';
        };
        # toolchain factory
        mkToolchain = name: pkgs.stdenv.mkDerivation {
          inherit name version;
          src = builtins.getAttr "toolchain_${name}" inputs;
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            python38
          ];
          phases = [ "installPhase" "fixupPhase" ];
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r $src/* $out
            runHook postInstall
          '';
        };
        # build all toolchains
        toolchains = builtins.foldl' (acc: elem: acc // { ${elem} = mkToolchain elem; }) {} [ "x86_64" "arm" "aarch64" ];
      in
      {
        devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
                toolchains.x86_64
                toolchains.arm
                toolchains.aarch64
                hosttools
                cmake
                python311Packages.west
            ];
            shellHook = ''
            export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
            '';
        };
      });
}
