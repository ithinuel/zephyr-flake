# Do not modify! This file is generated.

{
  description = "The real nix file";
  inputs = {
    dream2nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/dream2nix";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flakegen.url = "github:jorsn/flakegen";
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixpkgs_python38.url = "nixpkgs/nixos-23.11";
    pyocd = {
      flake = false;
      url = "github:pyocd/pyocd";
    };
    sdk_linux-aarch64 = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_linux-aarch64_minimal.tar.xz";
    };
    sdk_linux-x86_64 = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_linux-x86_64_minimal.tar.xz";
    };
    sdk_macos-aarch64 = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_macos-aarch64_minimal.tar.xz";
    };
    sdk_macos-x86_64 = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_macos-x86_64_minimal.tar.xz";
    };
    toolchain_linux-aarch64_aarch64-zephyr-elf = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_linux-aarch64_aarch64-zephyr-elf.tar.xz";
    };
    toolchain_linux-aarch64_arm-zephyr-eabi = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_linux-aarch64_arm-zephyr-eabi.tar.xz";
    };
    toolchain_linux-x86_64_aarch64-zephyr-elf = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_linux-x86_64_aarch64-zephyr-elf.tar.xz";
    };
    toolchain_linux-x86_64_arm-zephyr-eabi = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz";
    };
    toolchain_macos-aarch64_aarch64-zephyr-elf = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_macos-aarch64_aarch64-zephyr-elf.tar.xz";
    };
    toolchain_macos-aarch64_arm-zephyr-eabi = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_macos-aarch64_arm-zephyr-eabi.tar.xz";
    };
    toolchain_macos-x86_64_aarch64-zephyr-elf = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_macos-x86_64_aarch64-zephyr-elf.tar.xz";
    };
    toolchain_macos-x86_64_arm-zephyr-eabi = {
      flake = false;
      url = "file+https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_macos-x86_64_arm-zephyr-eabi.tar.xz";
    };
    zephyr = {
      flake = false;
      url = "github:zephyrproject-rtos/zephyr";
    };
  };
  outputs = inputs: inputs.flakegen ./flake.in.nix inputs;
}