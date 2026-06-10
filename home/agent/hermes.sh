# hermes — run the sandboxed Hermes agent against the current directory.
#
# `hermes` mounts $PWD into the container as /workspace and starts it. There is
# no mount list to manage: wherever you launch it is what the agent sees. The
# first time a given directory is used it must be confirmed (the agent runs in
# YOLO mode with full read/write access to that directory).

BASE_COMPOSE="/etc/nixos/home/agent/docker-compose.yml"
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hermes"
KNOWN_DIRS="$STATE_DIR/known-dirs"   # directories already confirmed
CURRENT="$STATE_DIR/current"         # workspace of the running container
PROJECT="hermes"
CONTAINER="hermes_agent"
DASHBOARD_URL="http://127.0.0.1:9119"

ASSUME_YES=0

# --- helpers ---------------------------------------------------------------

die()  { printf '\033[1;31mhermes:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*" >&2; }

compose() { HERMES_WORKSPACE="${HERMES_WORKSPACE:-$PWD}" docker compose -p "$PROJECT" -f "$BASE_COMPOSE" "$@"; }

is_running() { [ -n "$(docker ps -q -f "name=^${CONTAINER}\$" 2>/dev/null)" ]; }

confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  printf '\033[1;33m?\033[0m %s [y/N] ' "$1"
  local ans=""
  read -r ans || true
  case "$ans" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# Refuse mounts that would hand the agent far more than a project directory.
guard_workspace() {
  local ws="$1"
  case "$ws" in
    "$HOME") die "refusing to mount your entire home directory ($ws)" ;;
    / | /etc | /nix | /boot | /var | /usr | /root | /home)
      die "refusing to mount system directory: $ws" ;;
  esac
}

# --- commands --------------------------------------------------------------

cmd_start() {
  local ws="$PWD"
  guard_workspace "$ws"

  if is_running; then
    local cur=""; cur="$(cat "$CURRENT" 2>/dev/null || true)"
    if [ "$cur" = "$ws" ]; then
      info "Hermes is already running here ($ws)"
      info "Dashboard: $DASHBOARD_URL"
      return 0
    fi
    warn "Hermes is already running in: ${cur:-unknown}"
    confirm "Stop it and switch to $ws?" || die "left the running agent untouched"
  fi

  touch "$KNOWN_DIRS"
  if ! grep -qxF -- "$ws" "$KNOWN_DIRS"; then
    warn "First launch in $ws"
    warn "The agent runs in YOLO mode with full read/write access to this directory."
    confirm "Launch Hermes here?" || die "aborted"
    printf '%s\n' "$ws" >> "$KNOWN_DIRS"
  fi

  mkdir -p "$HOME/.hermes"   # ensure the data volume exists (else docker makes it root-owned)
  info "Starting Hermes with workspace: $ws"
  HERMES_WORKSPACE="$ws" compose up -d
  printf '%s\n' "$ws" > "$CURRENT"
  info "Dashboard: $DASHBOARD_URL"
}

cmd_shell() {
  is_running || die "Hermes is not running (start it with 'hermes')"
  if [ $# -gt 0 ]; then
    docker exec -it "$CONTAINER" "$@"
  else
    # Prefer bash; fall back to sh if the image lacks it.
    docker exec -it "$CONTAINER" bash 2>/dev/null || docker exec -it "$CONTAINER" sh
  fi
}

cmd_stop() {
  HERMES_WORKSPACE="$(cat "$CURRENT" 2>/dev/null || echo "$PWD")" compose down
  rm -f "$CURRENT"
  info "Stopped."
}

usage() {
  cat <<EOF
hermes — run the sandboxed Hermes agent against the current directory

  hermes [start]     mount \$PWD as /workspace and start the agent
                     (confirms the first time a directory is used)
  hermes stop        stop and remove the container
  hermes shell [cmd] open a shell in the container (or run cmd inside it)
  hermes status      show container status and active workspace
  hermes logs [-f]   show logs (use -f to follow)
  hermes dashboard   open the web dashboard ($DASHBOARD_URL)

Flags:
  -y, --yes          skip confirmation prompts
EOF
}

# --- dispatch --------------------------------------------------------------

mkdir -p "$STATE_DIR"

# Pull global flags out of the argument list.
argv=()
for a in "$@"; do
  case "$a" in
    -y|--yes) ASSUME_YES=1 ;;
    *) argv+=("$a") ;;
  esac
done
set -- "${argv[@]:-}"

cmd="${1:-start}"
[ $# -gt 0 ] && shift

case "$cmd" in
  start|"")  cmd_start ;;
  stop)      cmd_stop ;;
  shell|sh|exec) cmd_shell "$@" ;;
  status|ps) compose ps; [ -f "$CURRENT" ] && info "Workspace: $(cat "$CURRENT")" ;;
  logs)      compose logs "$@" ;;
  dashboard) info "Opening $DASHBOARD_URL"; xdg-open "$DASHBOARD_URL" >/dev/null 2>&1 & ;;
  help|-h|--help) usage ;;
  *)         die "unknown command: $cmd (try 'hermes help')" ;;
esac
