{ config, pkgs, lib, ... }:

let
  installerPath = "/home/fred/Media/Music/software/flstudio25.exe";
  winePrefix    = "${config.home.homeDirectory}/.local/share/fl-studio/wineprefix";
  wine          = pkgs.wineWow64Packages.staging;

  flstudio = pkgs.writeShellScriptBin "flstudio" ''
    export WINEPREFIX="${winePrefix}"
    export WINEARCH=win64
    export WINEDEBUG="-all"
    export WINEDLLOVERRIDES="mscoree,mshtml="
    export WINE_LARGE_ADDRESS_AWARE=1

    WINE="${wine}/bin/wine"
    WINESERVER="${wine}/bin/wineserver"
    FL64="$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 2025/FL64.exe"

    # ── First run: init prefix and install FL Studio ──────────────────────────
    if [ ! -f "$FL64" ]; then
      echo "[flstudio] First run — initialising Wine prefix..."

      "$WINE" wineboot --init
      "$WINESERVER" -w

      "$WINE" reg add \
        'HKLM\Software\Microsoft\Windows NT\CurrentVersion' \
        /v CurrentVersion /t REG_SZ /d '10.0' /f

      echo "[flstudio] Installing vcrun2019 via winetricks (needs internet, once only)..."
      ${pkgs.winetricks}/bin/winetricks -q vcrun2019
      "$WINESERVER" -w

      if [ ! -f "${installerPath}" ]; then
        echo "[flstudio] ERROR: installer not found at ${installerPath}"
        exit 1
      fi

      echo "[flstudio] Running FL Studio installer (this may take a few minutes)..."
      "$WINE" "${installerPath}" /S

      echo "[flstudio] Waiting for installation to complete..."
      WAIT=0
      until [ -f "$FL64" ] || [ "$WAIT" -ge 120 ]; do
        sleep 2
        WAIT=$((WAIT + 2))
      done
      "$WINESERVER" -w

      if [ ! -f "$FL64" ]; then
        echo "[flstudio] ERROR: FL64.exe not found after install — check installer manually."
        exit 1
      fi

      echo "[flstudio] Installation complete."
    fi

    # ── Launch ────────────────────────────────────────────────────────────────
    exec ${pkgs.pipewire.jack}/bin/pw-jack "$WINE" "$FL64" "$@"
  '';
in
{
  home.packages = [ flstudio wine pkgs.winetricks ];

  # ── Niri window rules ──────────────────────────────────────────────────────
  # Run `niri msg windows` after first launch to verify the exact app-id if
  # these rules don't fire.
  programs.niri.settings.window-rules = [
    {
      matches = [{ title = "FL Studio 2025"; }];
      default-column-width = { proportion = 0.9; };
    }
    {
      # Plugin GUIs, Mixer, Piano Roll — separate Wine windows, keep floating
      matches  = [{ app-id = "^(fl64|fl studio)"; }];
      excludes = [{ title  = "FL Studio 2025"; }];
      open-floating = true;
    }
  ];
}
