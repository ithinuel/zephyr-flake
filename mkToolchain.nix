{pkgs, inputs, name, version}: pkgs.stdenv.mkDerivation {
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
}
