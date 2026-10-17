# Synapse: Anki-compatible spaced-repetition app (Tauri), packaged from the
# upstream AppImage. https://github.com/Emadab/Synapse
{ appimageTools, fetchurl }:

let
  pname = "synapse";
  version = "1.0.0";
  src = fetchurl {
    url = "https://github.com/Emadab/Synapse/releases/download/v${version}/Synapse_${version}_amd64.AppImage";
    hash = "sha256-bPCKDaNutXJ78XXqIeCiAHacl75dD70XtZEvZhv45WQ=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Upstream names its binary and icon "desktop"; rename them to "synapse".
  extraInstallCommands = ''
    install -Dm444 ${contents}/usr/share/applications/Synapse.desktop \
      $out/share/applications/synapse.desktop
    substituteInPlace $out/share/applications/synapse.desktop \
      --replace-fail 'Exec=desktop' 'Exec=${pname}' \
      --replace-fail 'Icon=desktop' 'Icon=${pname}' \
      --replace-fail 'Categories=' 'Categories=Education;'

    for dir in ${contents}/usr/share/icons/hicolor/*/apps; do
      size=$(basename $(dirname $dir))
      if [ -f $dir/desktop.png ]; then
        install -Dm444 $dir/desktop.png $out/share/icons/hicolor/$size/apps/${pname}.png
      fi
    done
  '';
}
