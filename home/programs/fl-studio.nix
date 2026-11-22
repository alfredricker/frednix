{ pkgs, ... }:

# FL Studio under Wine-staging, with WineASIO bridging to PipeWire's JACK.
#
# First-time setup (once):
#   fl-studio-setup ~/Downloads/flstudio_win64_*.exe
# Then launch from rofi ("FL Studio") or run `fl-studio`.
#
# Other Windows installers (plugins, etc.) go into the same prefix:
#   fl-wine wine ~/Downloads/SomePluginSetup.exe
#   fl-wine winecfg
#   fl-wine winetricks corefonts
#
# In FL: Options → Audio settings → Device → "WineASIO". Buffer size is set by
# PipeWire's quantum (e.g. `pw-metadata -n settings 0 clock.force-quantum 128`).
let
  wine = pkgs.wineWow64Packages.stagingFull;
  wineasio = pkgs.wineasio;
  pwJack = pkgs.pipewire.jack;

  # nixpkgs installs the files as wineasio64.dll(.so), but the PE's internal
  # name is "wineasio.dll" and that's what wine's builtin loader searches
  # WINEDLLPATH for. Expose them under that name.
  wineasioDlls = pkgs.runCommand "wineasio-dllpath" { } ''
    mkdir -p $out/x86_64-windows $out/x86_64-unix
    ln -s ${wineasio}/lib/wine/x86_64-windows/wineasio64.dll $out/x86_64-windows/wineasio.dll
    ln -s ${wineasio}/lib/wine/x86_64-unix/wineasio64.dll.so $out/x86_64-unix/wineasio.dll.so
  '';

  # Shared environment for every FL-related wine invocation.
  env = ''
    export WINEPREFIX="''${FL_WINEPREFIX:-$HOME/.local/share/wineprefixes/fl-studio}"
    export WINEARCH=win64
    export WINEDEBUG="''${WINEDEBUG:--all}"
    export WINEDLLPATH="${wineasioDlls}''${WINEDLLPATH:+:$WINEDLLPATH}"
    # wineasio dlopens libjack.so.0 — make sure it gets PipeWire's, not jack2's.
    export LD_LIBRARY_PATH="${pwJack}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    # Wine 11 uses /dev/ntsync automatically when present (see system config).
    export PATH="${wine}/bin:${pkgs.winetricks}/bin:$PATH"

    # Create the prefix and (re-)register wineasio whenever its store path
    # changes, e.g. after a flake update.
    ensure_prefix() {
      if [ ! -f "$WINEPREFIX/system.reg" ]; then
        echo "Creating wine prefix at $WINEPREFIX ..."
        mkdir -p "$WINEPREFIX"
        wineboot --init
        wineserver --wait
      fi
      marker="$WINEPREFIX/.wineasio-registered"
      if [ "$(cat "$marker" 2>/dev/null)" != "${wineasio}" ]; then
        echo "Registering WineASIO ..."
        # Wine only resolves builtins that have a stub in system32; the PE
        # itself carries the builtin marker, so a copy serves as that stub.
        install -m644 ${wineasio}/lib/wine/x86_64-windows/wineasio64.dll \
          "$WINEPREFIX/drive_c/windows/system32/wineasio64.dll"
        if wine regsvr32 /s wineasio64.dll; then
          echo "${wineasio}" > "$marker"
        else
          echo "WARNING: WineASIO registration failed; will retry next launch." >&2
        fi
        wineserver --wait
      fi
    }
  '';

  fl-wine = pkgs.writeShellScriptBin "fl-wine" ''
    ${env}
    if [ $# -eq 0 ]; then
      echo "usage: fl-wine <command> [args...]   (e.g. fl-wine winecfg)" >&2
      exit 1
    fi
    ensure_prefix
    exec "$@"
  '';

  fl-studio-setup = pkgs.writeShellScriptBin "fl-studio-setup" ''
    set -e
    ${env}
    ensure_prefix
    if [ -n "$1" ]; then
      echo "Running installer: $1"
      wine "$1"
      wineserver --wait
    else
      echo "Prefix ready. Pass the FL Studio installer to run it:"
      echo "  fl-studio-setup ~/Downloads/flstudio_win64_<version>.exe"
    fi
  '';

  fl-studio = pkgs.writeShellScriptBin "fl-studio" ''
    ${env}
    ensure_prefix
    # Install dir is versioned ("FL Studio 2024", "FL Studio 2025", ...);
    # pick the newest one present.
    exe=$(ls -d "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio"*/FL64.exe 2>/dev/null | sort -V | tail -1)
    if [ -z "$exe" ]; then
      ${pkgs.libnotify}/bin/notify-send "FL Studio" "Not installed yet — run fl-studio-setup <installer.exe>"
      echo "FL Studio not found in $WINEPREFIX. Run: fl-studio-setup <installer.exe>" >&2
      exit 1
    fi
    cd "$(dirname "$exe")"
    exec wine "$exe" "$@"
  '';
in
{
  home.packages = [
    fl-studio
    fl-studio-setup
    fl-wine
    wineasio # provides `wineasio-settings` GUI
  ];

  xdg.desktopEntries.fl-studio = {
    name = "FL Studio";
    genericName = "Digital Audio Workstation";
    exec = "fl-studio %f";
    icon = "audio-x-generic";
    terminal = false;
    categories = [
      "AudioVideo"
      "Audio"
      "Music"
    ];
    mimeType = [ "application/x-flp" ];
  };
}
