# Zephyr Flakes

## Usage

In your direnv’s `.envrc`:

```shell
use flake github:ithinuel/zephyr-flakes
```

## Updating the flake

Edit `flake.in.nix`, then run.

```shell
nix run .#genflake flake.nix
```
