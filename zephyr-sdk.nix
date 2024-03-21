{ pkgs, inputs, target_archs }: {
  name = "zephyr-sdk";
  version = "0.16.5-1";
  srcs = map (arch: inputs."toolchain_${arch}") target_archs;
  nativeBuildInputs = with pkgs; [ autoPatchelfHook cmake which python38 ];
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
  '';

  # This is hacky but we need to make sure this is done after the autoPatchelfHook
  preFixup = ''
    postFixupHooks+=('
        for bin in $(ls $out/sysroots/x86_64-pokysdk-linux/usr/bin); do
            echo "Set interpreter for $bin…"
            patchelf --set-interpreter $out/sysroots/x86_64-pokysdk-linux/lib/ld-linux-x86-64.so.2 \
                $out/sysroots/x86_64-pokysdk-linux/usr/bin/$bin
        done
    ')
  '';
}
