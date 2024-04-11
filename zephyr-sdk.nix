{ version, host, toolchain }: {
  "toolchain-${toolchain}" = stdenv.mkDerivation ({ pkgs, lib, ncurses5, python38, libxcrypt-legacy, runtimeShell, ... }: {
    pname = "toolchain-${toolchain}";
    version = "${version}";

    src = inputs."toolchain_${host}_${toolchain}";

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      mkdir -p $out
      cp -r * $out
    '';

    preFixup = ''
      find $out -type f | while read f; do
        patchelf "$f" > /dev/null 2>&1 || continue
        patchelf --set-interpreter $(cat ${stdenv.cc}/nix-support/dynamic-linker) "$f" || true
        patchelf --set-rpath ${lib.makeLibraryPath [ "$out" stdenv.cc.cc ncurses5 python38 libxcrypt-legacy ]} "$f" || true
      done
    '';

    postFixup = ''
      mv $out/bin/arm-none-eabi-gdb $out/bin/arm-none-eabi-gdb-unwrapped
      cat <<EOF > $out/bin/arm-none-eabi-gdb
      #!${runtimeShell}
      export PYTHONPATH=${python38}/lib/python3.9
      export PYTHONHOME=${python38.interpreter}
      exec $out/bin/arm-none-eabi-gdb-unwrapped "\$@"
      EOF
      chmod +x $out/bin/arm-none-eabi-gdb
    '';

  });
}
