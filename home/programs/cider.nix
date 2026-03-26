{
  pkgs,
  appimageTools ? pkgs.appimageTools,
  lib ? pkgs.lib,
}:

appimageTools.wrapType2 rec {
  pname = "cider";
  version = "3.1.8";

  src = /home/fred/Applications/cider/cider-v${version}-linux-x64.AppImage;

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
    in
    ''
      install -m 444 -D ${contents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${contents}/usr/share/icons $out/share
    '';

  meta = with lib; {
    description = "A new look into listening and enjoying Apple Music in style and performance.";
    homepage = "https://cider.sh/";
    maintainers = [ maintainers.nicolaivds ];
    platforms = [ "x86_64-linux" ];
  };
}
