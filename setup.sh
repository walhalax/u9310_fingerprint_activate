#!/usr/bin/env bash
# setup.sh — Fujitsu LIFEBOOK U9310 シリーズで NB-2033-U 指紋認証を有効化する
# 再現性・冪等性を持つ単一目的のセットアップスクリプト。
#
# Usage:
#   sudo ./setup.sh                 # ステップごとに確認プロンプト
#   sudo ./setup.sh --yes           # 全て確認スキップ
#   sudo ./setup.sh --only fingerprint # fingerprint のみ
#   sudo ./setup.sh --only pam      # PAM + gsettings のみ
#   sudo ./setup.sh --dry-run       # 計画のみ
#
# ステップ:
#   fingerprint  fprintd + libfprint (NB-2033-U 暫定対応) を導入
#   pam          /etc/pam.d/gdm-password と gsettings を設定

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly VERSION="0.2.0"
export SETUP_VERSION="$VERSION"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/fingerprint.sh
source "$SCRIPT_DIR/lib/fingerprint.sh"
# shellcheck source=lib/pam.sh
source "$SCRIPT_DIR/lib/pam.sh"

readonly STEPS=(fingerprint pam)

step_descriptions() {
  cat <<EOF
fingerprint  fprintd + libfprint (MR !574) ビルド + /usr/local にインストール
pam          /etc/pam.d/gdm-password に pam_fprintd.so 挿入 + gsettings show-fingerprint 有効化
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
  NO_COLOR=1          カラー出力を無効化
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

  log "u9310_fingerprint_activate v$VERSION"
  log "Target: $OS $VERSION_ID"

  local steps_to_run=()
  for step in "${STEPS[@]}"; do
    if [[ -n "$only_steps" ]]; then
      [[ ",$only_steps," == *",$step,"* ]] && steps_to_run+=("$step")
    elif [[ ",$skip_steps," == *",$step,"* ]]; then
      continue
    else
      steps_to_run+=("$step")
    fi
  done

  log "Steps to run: ${steps_to_run[*]}"

  for step in "${steps_to_run[@]}"; do
    if [[ $yes -eq 0 ]] && ! confirm "Run step '$step'?"; then
      log "Skipping $step"
      continue
    fi
    case "$step" in
      fingerprint) fingerprint_step "$dry" ;;
      pam)         pam_step "$dry" ;;
    esac
  done

  log "All requested steps completed."
  log "After PAM step: log out, then test Settings → Users → Fingerprint, and GDM login."
}

main "$@"