#!/usr/bin/env bash
# uninstall.sh — セットアップで行った変更を巻き戻す
# ステップごとに個別実行可能: ./uninstall.sh --only fingerprint

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 [--only STEP[,STEP]] [--yes]

Steps:
  apt         Phased-updates drop-in を削除
  ppa         追加した PPA を削除
  fingerprint libfprint (MR !574) ビルド成果物を削除し、fprintd 再起動
  pam         /etc/pam.d/gdm-password の pam_fprintd.so 行を削除
  crush       ~/.config/crush/crushrc と ~/crush/setting.md を削除 (任意)
  tailscale   Tailscale をログアウト + パッケージ削除
  all         上記すべて

EOF
}

main() {
  local yes=0 only=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes) yes=1; shift ;;
      --only) only="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) die "Unknown: $1" ;;
    esac
  done

  [[ $EUID -ne 0 ]] && die "Must be root"

  local steps=("${only[@]:-all}")
  [[ -z "$only" ]] && steps=(apt ppa fingerprint pam crush tailscale)

  for step in "${steps[@]}"; do
    case "$step" in
      apt)
        rm -f /etc/apt/apt.conf.d/99no-phased-updates
        ok "removed phased-updates drop-in"
        ;;
      ppa)
        rm -f /etc/apt/sources.list.d/{brave-browser-release,vscodium,nodesource,charm}.list
        rm -f /etc/apt/keyrings/{brave-browser-release,vscodium,nodesource,charm}.{gpg,asc}
        ok "removed extra PPAs"
        ;;
      fingerprint)
        if [[ -d /usr/local/src/lifebook-libfprint-installer/libfprint/builddir ]]; then
          ( cd /usr/local/src/lifebook-libfprint-installer/libfprint && \
            ninja -C builddir uninstall )
        fi
        rm -f /usr/local/lib/x86_64-linux-gnu/libfprint-2.so*
        rm -f /usr/local/lib/fprint-2/*
        ldconfig
        systemctl restart fprintd
        ok "removed custom libfprint"
        ;;
      pam)
        if [[ -f /etc/pam.d/gdm-password ]]; then
          sed -i '/^auth    sufficient      pam_fprintd.so$/d' /etc/pam.d/gdm-password
          ok "removed pam_fprintd.so line"
        fi
        ;;
      crush)
        rm -f "$HOME/.config/crush/crushrc" "$HOME/crush/setting.md"
        ok "removed crush globals"
        ;;
      tailscale)
        tailscale logout 2>/dev/null || true
        apt-get remove -y tailscale || true
        ok "tailscale removed"
        ;;
      all) ;;
      *) die "Unknown step: $step" ;;
    esac
  done
}

main "$@"