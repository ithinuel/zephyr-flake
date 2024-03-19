pkgs: sdk: pkgs.stdenv.mkDerivation {
  name = "hosttools";
  version = "0.16.5-1";
  src = sdk;
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
}
