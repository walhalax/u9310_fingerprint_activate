# common.sh — 共通ユーティリティ (色、ログ、確認プロンプト、OS検出)

# カラー出力 (NO_COLOR 対応)
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  readonly C_RED=$'\033[31m'
  readonly C_GREEN=$'\033[32m'
  readonly C_YELLOW=$'\033[33m'
  readonly C_BLUE=$'\033[34m'
  readonly C_BOLD=$'\033[1m'
  readonly C_RESET=$'\033[0m'
else
  readonly C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_BOLD="" C_RESET=""
fi

log()   { printf "%s[INFO]%s %s\n" "$C_BLUE" "$C_RESET" "$*"; }
warn()  { printf "%s[WARN]%s %s\n" "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()   { printf "%s[ERR ]%s %s\n" "$C_RED" "$C_RESET" "$*" >&2; }
ok()    { printf "%s[OK  ]%s %s\n" "$C_GREEN" "$C_RESET" "$*"; }
die()   { err "$*"; exit 1; }

step()  { printf "\n%s== %s ==%s\n" "$C_BOLD" "$*" "$C_RESET"; }

confirm() {
  local prompt="$1"
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

run() {
  if [[ "${SETUP_DRY:-0}" == "1" ]]; then
    log "DRY-RUN: $*"
  else
    "$@"
  fi
}

# OS 検出 (Ubuntu 系のみサポート)
detect_target_os() {
  if [[ ! -f /etc/os-release ]]; then
    err "/etc/os-release not found"
    return 1
  fi
  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    err "Unsupported distribution: $ID (Ubuntu required)"
    return 1
  fi

  local ver="${VERSION_ID:-0}"
  local major="${ver%%.*}"
  if (( major < 24 )); then
    err "Ubuntu $ver is too old (24.04+ required)"
    return 1
  fi

  export OS VERSION_ID UBUNTU_CODENAME
  return 0
}

# ~/.config/u9310_fingerprint_activate/env を読み込む (任意)
load_env_file() {
  local env_file="$HOME/.config/u9310_fingerprint_activate/env"
  if [[ -f "$env_file" ]]; then
    log "Loading env from $env_file"
    # shellcheck disable=SC1090
    set -a; source "$env_file"; set +a
  fi
}