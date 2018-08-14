{ stdenv
, apk-tools-static
, proot }:
{ apks
, name ? "alpine-system" }:
stdenv.mkDerivation {
  inherit name;
  buildInputs = [ apk-tools-static proot ];

  phases = [ "unpackPhase" "configurePhase" "buildPhase" ];

  src = ./.;

  configurePhase = with stdenv.lib; ''
    # apks to install
    export APKS="${concatStringsSep " " apks}"

    # tools
    export PROOT=${proot}/bin/proot
    export APK_STATIC=${apk-tools-static}/bin/apk.static
  '';

}
