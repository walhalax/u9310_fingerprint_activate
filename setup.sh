#!/usr/bin/env bash
# u9310_fingerprint_activate — Lifebook U9300/U9311/U9312 初期セットアップスクリプト
# 再現性・冪等性を重視。各ステップは個別に有効化/無効化可能。
#
# Usage:
#   ./setup.sh                 # 全ステップを対話で確認しながら実行
#   ./setup.sh --yes           # 確認プロンプトをスキップ
#   ./setup.sh --only fingerprint # fingerprint ステップのみ実行
#   ./setup.sh --skip tailscale   # tailscale をスキップ
#
# 必要な環境変数 (任意):
#   TS_AUTHKEY                 # Tailscale 認証キー
#   SETUP_EXTRA_PPAS=0         # 追加 PPA を無効化
#   SETUP_PHASED=0             # phased-updates の強制無効化

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly VERSION="0.1.0"
export SETUP_VERSION="$VERSION"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/apt.sh
source "$SCRIPT_DIR/lib/apt.sh"
# shellcheck source=lib/ppa.sh
source "$SCRIPT_DIR/lib/ppa.sh"
# shellcheck source=lib/fingerprint.sh
source "$SCRIPT_DIR/lib/fingerprint.sh"
# shellcheck source=lib/pam.sh
source "$SCRIPT_DIR/lib/pam.sh"
# shellcheck source=lib/crush.sh
source "$SCRIPT_DIR/lib/crush.sh"
# shellcheck source=lib/tailscale.sh
source "$SCRIPT_DIR/lib/tailscale.sh"

# 利用可能なステップ名
readonly STEPS=(
  apt
  ppa
  fingerprint
  pam
  crush
  tailscale
)

# ステップの説明 (--list で表示)
step_descriptions() {
  cat <<EOF
apt         apt update/upgrade + phased-updates 強制有効化
ppa         任意 PPA 追加 (brave/vscodium/nodesource/charm)
fingerprint fprintd + libfprint (NB-2033-U 暫定対応) 導入
pam         /etc/pam.d/gdm-password + gsettings 設定
crush       crush + ~/.config/crush/crushrc + グローバル setting.md
tailscale   Tailscale インストール (TS_AUTHKEY 必要)
EOF
}

usage() {
  cat <<EOF
u9310_fingerprint_activate v$VERSION

Usage: $0 [options]

Options:
  --yes               確認プロンプトをスキップ
  --only STEP[,STEP]  指定ステップのみ実行
  --skip STEP[,STEP]  指定ステップをスキップ
  --list              ステップ一覧を表示
  --dry-run           実際の変更を行わず計画だけ表示
  -h, --help          このヘルプを表示

Environment:
  TS_AUTHKEY          Tailscale 認証キー (tailscale ステップ)
  SETUP_EXTRA_PPAS=0  追加 PPA を無効化
  SETUP_PHASED=0      phased-updates 強制を無効化

EOF
}

main() {
  local yes=0 dry=0
  local only_steps="" skip_steps=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes) yes=1; shift ;;
      --only) only_steps="$2"; shift 2 ;;
      --skip) skip_steps="$2"; shift 2 ;;
      --dry-run) dry=1; shift ;;
      --list) step_descriptions; exit 0 ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  if [[ $EUID -ne 0 ]]; then
    die "This script must be run as root (sudo ./setup.sh)."
  fi

  detect_target_os || die "Unsupported OS. Ubuntu 24.04+ required."
  load_env_file

  log "u9310_fingerprint_activate v$VERSION"
  log "Target: $OS $VERSION_ID"

  local steps_to_run=()
  for step in "${STEPS[@]}"; do
    if [[ -n "$only_steps" ]]; then
      if [[ ",$only_steps," == *",$step,"* ]]; then
        steps_to_run+=("$step")
      fi
    elif [[ ",$skip_steps," == *",$step,"* ]]; then
      continue
    else
      steps_to_run+=("$step")
    fi
  done

  log "Steps to run: ${steps_to_run[*]}"

  for step in "${steps_to_run[@]}"; do
    if [[ $yes -eq 0 ]]; then
      if ! confirm "Run step '$step'?"; then
        log "Skipping $step"
        continue
      fi
    fi

    case "$step" in
      apt) apt_step "$dry" ;;
      ppa) ppa_step "$dry" ;;
      fingerprint) fingerprint_step "$dry" ;;
      pam) pam_step "$dry" ;;
      crush) crush_step "$dry" ;;
      tailscale) tailscale_step "$dry" ;;
    esac
  done

  log "All requested steps completed."
  log "Run ./uninstall.sh to revert changes."
}

main "$@"