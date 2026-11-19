#!@shell@
# KytyPS5 keeps saves, trophies, shader caches and logs next to its own binary,
# and the Nix store is read-only. Run it from a per-user directory instead:
# program files are copied there (symlinks would resolve back into the store)
# and refreshed whenever the installed package changes.
set -eu

app=@app@
dir="${KYTYPS5_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/kytyps5}"
stamp="$dir/.nix-package"

mkdir -p "$dir"

if [ "$(cat "$stamp" 2>/dev/null || true)" != "$app" ]; then
  for src in "$app"/*; do
    dst="$dir/${src##*/}"
    if [ -d "$src" ]; then
      # Read-only data: link it. Never replace a real directory.
      if [ -L "$dst" ] || [ ! -e "$dst" ]; then
        ln -sfn "$src" "$dst"
      fi
    else
      rm -f "$dst"
      cp --reflink=auto "$src" "$dst"
    fi
  done
  printf '%s\n' "$app" > "$stamp"
fi

cd "$dir"
exec "$dir/kyty_launcher" "$@"
