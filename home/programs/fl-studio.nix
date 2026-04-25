{ config, pkgs, lib, ... }:

let
  installerPath = "/home/fred/Media/Music/software/flstudio25.exe";
  winePrefix    = "${config.home.homeDirectory}/.local/share/fl-studio/wineprefix";
  wine          = pkgs.wineWow64Packages.staging;

  flstudio = pkgs.writeShellScriptBin "flstudio" ''
    export WINEPREFIX="${winePrefix}"
    export WINEARCH=win64
    export WINEDEBUG="-all"
    export WINEDLLOVERRIDES="mscoree,mshtml="   # suppress Mono/Gecko install prompts
    export WINE_LARGE_ADDRESS_AWARE=1

    WINE="${wine}/bin/wine"
    WINESERVER="${wine}/bin/wineserver"

    # ── First run: init prefix and install FL Studio ──────────────────────────
    if [ ! -f "$WINEPREFIX/.fl-studio-installed" ]; then
      echo "[flstudio] First run — initialising Wine prefix..."

      "$WINE" wineboot --init
      "$WINESERVER" -w

      # Windows 10
      "$WINE" reg add \
        'HKLM\Software\Microsoft\Windows NT\CurrentVersion' \
        /v CurrentVersion /t REG_SZ /d '10.0' /f

      # Visual C++ 2019 runtime — required by FL Studio
      echo "[flstudio] Installing vcrun2019 via winetricks (needs internet, once only)..."
      ${pkgs.winetricks}/bin/winetricks -q vcrun2019
      "$WINESERVER" -w

      if [ ! -f "${installerPath}" ]; then
        echo "[flstudio] ERROR: installer not found at ${installerPath}"
        echo "           Place your FL Studio .exe there and re-run flstudio."
        exit 1
      fi

      echo "[flstudio] Running FL Studio installer silently..."
      "$WINE" "${installerPath}" /S
      "$WINESERVER" -w

      touch "$WINEPREFIX/.fl-studio-installed"
      echo "[flstudio] Installation complete."
    fi

    # ── Launch ────────────────────────────────────────────────────────────────
    # pw-jack makes PipeWire present itself as a JACK server to Wine
    exec ${pkgs.pipewire.jack}/bin/pw-jack "$WINE" \
      "$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 2025/FL64.exe" "$@"
  '';
in
{
  home.packages = [ flstudio wine pkgs.winetricks ];

  # ── Niri window rules ──────────────────────────────────────────────────────
  # Wine runs via xwayland-satellite; app-id reflects WM_CLASS set by Wine.
  # Run `niri msg windows` after first launch to verify the exact app-id if
  # these rules don't fire — Wine sometimes uses the exe name or window title.
  programs.niri.settings.window-rules = [
    {
      # Main FL Studio frame: 90% column width
      matches = [{ title = "FL Studio 2025"; }];
      default-column-width = { proportion = 0.9; };
    }
    {
      # Plugin GUIs, Mixer, Piano Roll, etc. — same Wine app-id but different title
      # These open as separate Wayland/X11 windows; keep them floating.
      matches  = [{ app-id = "^(fl64|fl studio)"; }];
      excludes = [{ title  = "FL Studio 2025"; }];
      open-floating = true;
    }
  ];
}
