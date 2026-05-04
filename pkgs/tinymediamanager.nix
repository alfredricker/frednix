{
  fetchurl,
  jre,
  lib,
  libmediainfo,
  libzen,
  makeWrapper,
  stdenv,
  xz,
}:
let
  ldpath = lib.makeLibraryPath [
    libmediainfo
    libzen
    stdenv.cc.cc.lib
  ];
in
stdenv.mkDerivation rec {
  pname = "tinyMediaManager";
  version = "5.1.4";

  src = fetchurl {
    url = "https://release.tinymediamanager.org/v5/dist/${pname}-${version}-linux-amd64.tar.xz";
    hash = "sha256-3DlAC9KXSkDSsA9Lpf1jXl+GZL3+MowefvfDV6pgfbY=";
    postFetch = ''
      cp $out src.xz
      ${xz}/bin/unxz src.xz --stdout > $out
    '';
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share

    cp -R ${pname} $out/share/

    makeWrapper ${jre}/bin/java $out/bin/${pname} \
      --add-flags "-Duser.dir=\$HOME/.local/share/${pname} -classpath $out/share/${pname}/tmm.jar:$out/share/${pname}/lib/* -Xms64m -Xmx512m -Xss512k -XX:+IgnoreUnrecognizedVMOptions -XX:+UseG1GC -XX:+UseStringDeduplication -Dsun.java2d.renderer=sun.java2d.marlin.MarlinRenderingEngine -splash:splashscreen.png -Djava.net.preferIPv4Stack=true -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -Djna.nosys=true -Dtmm.consoleloglevel=NONE -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true org.tinymediamanager.TinyMediaManager" \
      --set LD_LIBRARY_PATH ${ldpath}

    runHook postInstall
  '';
}
