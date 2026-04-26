# FL Studio (Wine) — Operations Guide

## Logging

Run with `--debug` to capture Wine output to `/tmp/flstudio-wine.log`:

```bash
flstudio --debug
# open a plugin, reproduce crash, then:
tail -200 /tmp/flstudio-wine.log
```

Useful greps:
```bash
grep -i "err\|warn\|exception\|fault\|failed" /tmp/flstudio-wine.log
grep -i "loaddll\|module" /tmp/flstudio-wine.log   # DLL load trace
grep -i "wineasio\|jack" /tmp/flstudio-wine.log     # audio driver
```

Debug mode sets `WINEDEBUG="+seh,+loaddll,+module"`. Normal mode sets `WINEDEBUG="-all"` (silent).


## Patches flag (`~/.local/share/fl-studio/wineprefix/.patches-applied`)

The patches block (winetricks vcrun2019, dxvk, d3dcompiler_47, corefonts, mfc140, vb6run,
dotnet48, and wineasio regsvr32) runs **once** on first launch and is gated by this flag file.

**To re-run all patches** (e.g. after adding a new winetricks component to fl-studio.nix):
```bash
rm ~/.local/share/fl-studio/wineprefix/.patches-applied
flstudio
```

**If winetricks hangs** (stray Wine process from a crashed session):
```bash
wineserver -k    # in a second terminal
# then relaunch flstudio — patches resume
```

winetricks uses `wineserver -w` internally between component installs; this is normal and
expected. It only hangs if a stray Wine process is left over from a crash.


## Wine prefix

Location: `~/.local/share/fl-studio/wineprefix`

This directory is **mutable** — FL Studio writes its license, audio config, project history,
and plugin cache here. Do not delete it unless you want to reinstall everything from scratch.

Full reset:
```bash
rm -rf ~/.local/share/fl-studio/wineprefix
flstudio   # re-installs FL Studio and re-applies all patches
```

The installer is read from `/home/fred/Media/Music/software/flstudio25.exe`.


## wineasio name-fix symlink

`~/.local/share/fl-studio/wine-builtins/x86_64-unix/wineasio.dll.so`

This symlink is recreated on every `flstudio` launch. It maps the name Wine expects
(`wineasio.dll.so`) to the file nixpkgs ships (`wineasio64.dll.so`). If wineasio stops
working after a nixpkgs update, check that the symlink target still exists:

```bash
ls -la ~/.local/share/fl-studio/wine-builtins/x86_64-unix/
```

After verifying wineasio is registered, set the driver in FL Studio:
**Options → Audio Settings → Audio device → select "wineasio"**


## Project directory (declarative symlink)

FL Studio's default project path inside the prefix is:
```
~/.local/share/fl-studio/wineprefix/drive_c/users/fred/Documents/Image-Line/FL Studio/Projects
```

To redirect this to a real Linux directory declaratively, add to `fl-studio.nix`:

```nix
home.activation.flstudioProjectDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
  projectDir="/home/fred/Media/Music/Projects"
  wineTarget="$HOME/.local/share/fl-studio/wineprefix/drive_c/users/fred/Documents/Image-Line/FL Studio"
  mkdir -p "$projectDir"
  mkdir -p "$wineTarget"
  if [ ! -L "$wineTarget/Projects" ]; then
    rm -rf "$wineTarget/Projects"
    ln -s "$projectDir" "$wineTarget/Projects"
  fi
''
```

This runs on every `home-manager switch`. The symlink makes FL Studio write/read projects
directly to your Linux path — visible to both Wine and native Linux tools.

You can do the same for Samples, Presets, etc. by adding more `ln -s` lines.


## Windows plugins (Serum, Massive, Waves, etc.)

**Short answer: commercial plugins cannot be fetched declaratively.** They require account
login, license activation servers, and sometimes custom installers. There is no stable,
hashable download URL.

**Practical workflow:**

1. Download the Windows VST3/VST2 installer from the vendor's site manually.
2. Run the installer inside the Wine prefix:
   ```bash
   WINEPREFIX=~/.local/share/fl-studio/wineprefix wine ~/Downloads/SerumSetup.exe
   ```
3. FL Studio will auto-detect VST3 plugins in `C:\Program Files\Common Files\VST3`.
   For VST2, point FL Studio at the install directory:
   **Options → Manage plugins → Add search path**

**Free/open plugins that could be fetched declaratively:**

Some free Windows plugins have stable GitHub release URLs. You could add a `fetchurl`
block in fl-studio.nix to download the DLL to a declared path, then symlink it into the
prefix's VST directory. This is only viable for plugins with:
- A stable, versioned download URL
- A known SHA256 hash
- A simple DLL drop (no installer required)

Example skeleton (not wired up yet):
```nix
let
  somePlugin = pkgs.fetchurl {
    url = "https://example.com/plugin-1.0.0-win64.dll";
    sha256 = "...";
  };
in
# then in activation script:
# ln -sf ${somePlugin} "$WINEPREFIX/drive_c/Program Files/Common Files/VST3/someplugin.dll"
```

Waves and similar commercial suites use their own license managers (Waves Central, iLok)
which are themselves Windows apps — realistically these are installed manually and live
entirely in the mutable wineprefix.
