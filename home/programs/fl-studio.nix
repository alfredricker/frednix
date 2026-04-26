{ config, pkgs, lib, ... }:

let
  installerPath   = "/home/fred/Media/Music/software/flstudio25.exe";
  winePrefix      = "${config.home.homeDirectory}/.local/share/fl-studio/wineprefix";
  # Wine expects builtin "wineasio.dll" but nixpkgs ships "wineasio64.dll.so".
  # We maintain a local symlink dir that maps the expected name → actual file.
  wineBuiltinsDir = "${config.home.homeDirectory}/.local/share/fl-studio/wine-builtins";
  wine            = pkgs.wineWow64Packages.staging;

  flstudio = pkgs.writeShellScriptBin "flstudio" ''
    export WINEPREFIX="${winePrefix}"
    export WINEARCH=win64
    export WINEDEBUG="-all"
    export WINE_LARGE_ADDRESS_AWARE=1
    export WINEDLLOVERRIDES="mscoree,mshtml=;wineasio64=b"

    # WINEDLLPATH: first check our local name-fix dir, then the Nix store dir
    export WINEDLLPATH="${wineBuiltinsDir}:${pkgs.wineasio}/lib/wine"

    WINE="${wine}/bin/wine"
    WINESERVER="${wine}/bin/wineserver"
    FL64="$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 2025/FL64.exe"

    # ── Ensure wineasio name symlink is current (runs every launch) ───────────
    # Wine reads the PE stub's internal module name ("wineasio") and looks for
    # "wineasio.dll.so", but nixpkgs ships "wineasio64.dll.so". Symlink fixes it.
    mkdir -p "${wineBuiltinsDir}/x86_64-unix"
    ln -sf "${pkgs.wineasio}/lib/wine/x86_64-unix/wineasio64.dll.so" \
           "${wineBuiltinsDir}/x86_64-unix/wineasio.dll.so"

    # ── Install FL Studio (first run only) ────────────────────────────────────
    if [ ! -f "$FL64" ]; then
      echo "[flstudio] First run — initialising Wine prefix..."

      "$WINE" wineboot --init
      "$WINESERVER" -w

      "$WINE" reg add \
        'HKLM\Software\Microsoft\Windows NT\CurrentVersion' \
        /v CurrentVersion /t REG_SZ /d '10.0' /f

      if [ ! -f "${installerPath}" ]; then
        echo "[flstudio] ERROR: installer not found at ${installerPath}"
        exit 1
      fi

      echo "[flstudio] Running FL Studio installer..."
      "$WINE" "${installerPath}" /S

      echo "[flstudio] Waiting for installation to complete..."
      WAIT=0
      until [ -f "$FL64" ] || [ "$WAIT" -ge 120 ]; do
        sleep 2
        WAIT=$((WAIT + 2))
      done
      "$WINESERVER" -k

      if [ ! -f "$FL64" ]; then
        echo "[flstudio] ERROR: FL64.exe not found after install."
        exit 1
      fi

      echo "[flstudio] FL Studio installed."
    fi

    # ── Apply patches (once, re-delete .patches-applied to rerun) ────────────
    if [ ! -f "$WINEPREFIX/.patches-applied" ]; then
      echo "[flstudio] Applying Wine patches (needs internet, once only)..."

      echo "[flstudio]   vcrun2019..."
      ${pkgs.winetricks}/bin/winetricks -q vcrun2019

      echo "[flstudio]   dxvk..."
      ${pkgs.winetricks}/bin/winetricks -q dxvk

      echo "[flstudio]   d3dcompiler_47..."
      ${pkgs.winetricks}/bin/winetricks -q d3dcompiler_47

      echo "[flstudio]   corefonts..."
      ${pkgs.winetricks}/bin/winetricks -q corefonts

      echo "[flstudio]   mfc140..."
      ${pkgs.winetricks}/bin/winetricks -q mfc140

      echo "[flstudio]   vb6run..."
      ${pkgs.winetricks}/bin/winetricks -q vb6run

      echo "[flstudio]   dotnet48..."
      ${pkgs.winetricks}/bin/winetricks -q dotnet48

      echo "[flstudio]   wineasio..."
      ${pkgs.pipewire.jack}/bin/pw-jack "$WINE" \
        "C:\\windows\\system32\\regsvr32.exe" \
        "Z:${pkgs.wineasio}/lib/wine/x86_64-windows/wineasio64.dll"
      "$WINESERVER" -k

      touch "$WINEPREFIX/.patches-applied"
      echo "[flstudio] Patches applied."
      echo "[flstudio] In FL Studio: Options > Audio Settings > select 'wineasio' as driver."
    fi

    # ── Install new plugins from ~/Media/Music/software/plugins/ ─────────────
    PLUGIN_DIR="$HOME/Media/Music/software/plugins"
    PLUGIN_MANIFEST="$WINEPREFIX/.installed-plugins"
    touch "$PLUGIN_MANIFEST"
    if [ -d "$PLUGIN_DIR" ]; then
      for installer in "$PLUGIN_DIR"/*.exe; do
        [ -f "$installer" ] || continue
        name="$(basename "$installer")"
        if ! grep -qxF "$name" "$PLUGIN_MANIFEST"; then
          echo "[flstudio] New plugin installer detected: $name"
          echo "[flstudio] Running installer — complete setup in the GUI window..."
          "$WINE" "$installer"
          "$WINESERVER" -k
          echo "$name" >> "$PLUGIN_MANIFEST"
          echo "[flstudio] $name recorded in manifest."
        fi
      done
    fi

    # ── Launch ────────────────────────────────────────────────────────────────
    # Pass --debug as first arg to enable Wine crash/exception logging to ~/flstudio-wine.log
    if [ "''${1:-}" = "--debug" ]; then
      shift
      export WINEDEBUG="+seh,+loaddll,+module"
      echo "[flstudio] Debug mode — logging to /tmp/flstudio-wine.log"
      exec ${pkgs.pipewire.jack}/bin/pw-jack "$WINE" "$FL64" "$@" \
        2>&1 | tee /tmp/flstudio-wine.log
    fi

    exec ${pkgs.pipewire.jack}/bin/pw-jack "$WINE" "$FL64" "$@"
  '';
in
{
  home.packages = [ flstudio wine pkgs.winetricks pkgs.wineasio ];

  home.activation.flstudioProjectDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    projectDir="$HOME/Media/Music/projects"
    wineTarget="$HOME/.local/share/fl-studio/wineprefix/drive_c/users/fred/Documents/Image-Line/FL Studio"
    mkdir -p "$projectDir"
    mkdir -p "$wineTarget"
    if [ ! -L "$wineTarget/Projects" ]; then
      rm -rf "$wineTarget/Projects"
      ln -s "$projectDir" "$wineTarget/Projects"
    fi
  '';

  programs.niri.settings.window-rules = [
    {
      matches = [{ title = "FL Studio 2025"; }];
      default-column-width = { proportion = 0.9; };
    }
    {
      matches  = [{ app-id = "^(fl64|fl studio)"; }];
      excludes = [{ title  = "FL Studio 2025"; }];
      open-floating = true;
    }
  ];
}
