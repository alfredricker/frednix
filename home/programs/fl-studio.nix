{ config, pkgs, lib, ... }:

let
  installerPath = "/home/fred/Media/Music/software/flstudio25.exe";
  winePrefix    = "${config.home.homeDirectory}/.local/share/fl-studio/wineprefix";
  wine          = pkgs.wineWow64Packages.staging;

  flstudio = pkgs.writeShellScriptBin "flstudio" ''
    export WINEPREFIX="${winePrefix}"
    export WINEARCH=win64
    export WINEDEBUG="-all"
    export WINE_LARGE_ADDRESS_AWARE=1

    # wineasio=b: use the builtin (native) wineasio instead of any Windows version
    export WINEDLLOVERRIDES="mscoree,mshtml=;wineasio=b"

    # Tells Wine where to find wineasio64.dll.so (the Unix-side builtin)
    export WINEDLLPATH="${pkgs.wineasio}/lib/wine"

    WINE="${wine}/bin/wine"
    WINESERVER="${wine}/bin/wineserver"
    FL64="$WINEPREFIX/drive_c/Program Files/Image-Line/FL Studio 2025/FL64.exe"

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
      "$WINESERVER" -w

      if [ ! -f "$FL64" ]; then
        echo "[flstudio] ERROR: FL64.exe not found after install."
        exit 1
      fi

      echo "[flstudio] FL Studio installed."
    fi

    # ── Apply patches (idempotent, re-runs if patches change) ─────────────────
    if [ ! -f "$WINEPREFIX/.patches-applied" ]; then
      echo "[flstudio] Applying Wine patches (needs internet, once only)..."

      # vcrun2019 is a superset of 2015/2017 — covers all stock plugin requirements
      echo "[flstudio]   vcrun2019..."
      ${pkgs.winetricks}/bin/winetricks -q vcrun2019
      "$WINESERVER" -w

      # DXVK — translates D3D9/10/11 → Vulkan, fixes browser panel flashing
      echo "[flstudio]   dxvk..."
      ${pkgs.winetricks}/bin/winetricks -q dxvk
      "$WINESERVER" -w

      # wineasio — native JACK ASIO driver; gives FL Studio a real low-latency
      # ASIO interface backed by PipeWire JACK.
      # regsvr32 must run inside pw-jack so the DLL can load libjack at registration time.
      echo "[flstudio]   wineasio..."
      cp "${pkgs.wineasio}/lib/wine/x86_64-windows/wineasio64.dll" \
        "$WINEPREFIX/drive_c/windows/system32/wineasio64.dll"
      ${pkgs.pipewire.jack}/bin/pw-jack "$WINE" regsvr32 wineasio64.dll
      "$WINESERVER" -w

      touch "$WINEPREFIX/.patches-applied"
      echo "[flstudio] Patches applied."
      echo "[flstudio] In FL Studio: Options > Audio Settings > select 'wineasio' as driver."
    fi

    # ── Launch ────────────────────────────────────────────────────────────────
    exec ${pkgs.pipewire.jack}/bin/pw-jack "$WINE" "$FL64" "$@"
  '';
in
{
  home.packages = [ flstudio wine pkgs.winetricks pkgs.wineasio ];

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
