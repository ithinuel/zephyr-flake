# Zephyr Flakes

## Usage

In your direnv’s `.envrc`:

```shell
use flake github:ithinuel/zephyr-flakes
```

On a fresh zephyr clone:
```shell
west init -l .
west update
west build …
```

## Updating the flake

Edit `flake.in.nix`, then run.

```shell
nix run .#genflake flake.nix
```

## Building the docs

```shell
nix develop github:ithinuel/zephyr-flakes#doc
cmake -GNinja -B_build .
cd _build
ninja html
```
