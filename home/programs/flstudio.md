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

### Auto-installer manifest

Drop any Windows plugin `.exe` into `~/Media/Music/software/plugins/`. On the next
`flstudio` launch, the script detects files not yet in the manifest and runs each one
interactively (GUI installer — click through as normal). When the installer closes, the
filename is recorded and it won't run again.

**Manifest location:** `~/.local/share/fl-studio/wineprefix/.installed-plugins`
One filename per line.

**To re-run an installer** (e.g. to repair or update a plugin):
```bash
sed -i '/SerumSetup.exe/d' ~/.local/share/fl-studio/wineprefix/.installed-plugins
# then relaunch flstudio
```

**To re-run all plugin installers:**
```bash
> ~/.local/share/fl-studio/wineprefix/.installed-plugins
# then relaunch flstudio
```

After installation, FL Studio auto-detects VST3 plugins placed in:
`C:\Program Files\Common Files\VST3`

For VST2, add the install directory manually:
**Options → Manage plugins → Add search path**

### Note on commercial plugins

Serum, Massive, Waves etc. require license activation after install (iLok, account login,
etc.) — that step is always manual. The manifest handles the installer run; activation
happens inside FL Studio or the plugin's own launcher.

Waves in particular uses Waves Central (a separate Windows app) for license management —
drop the Waves Central installer in the plugins folder and it will run on next launch.

### Free/open plugins (declarative DLL drop)

Some free plugins are a single DLL with no installer. These can be declared in
`fl-studio.nix` with `fetchurl` and symlinked directly into the VST directory:

```nix
let
  somePlugin = pkgs.fetchurl {
    url = "https://example.com/plugin-1.0.0-win64.dll";
    sha256 = "...";
  };
in
# in home.activation or the launch script:
# ln -sf ${somePlugin} "$WINEPREFIX/drive_c/Program Files/Common Files/VST3/someplugin.dll"
```
