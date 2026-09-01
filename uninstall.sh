#!/usr/bin/env bash
# uninstall.sh — setup.sh で行った指紋セットアップ変更を巻き戻す

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<EOF
Usage: $0 [--only STEP[,STEP]] [--yes]

Steps:
  fingerprint libfprint (MR !574) ビルド成果物を削除し、fprintd を再起動
  pam         /etc/pam.d/gdm-password の pam_fprintd.so 行を削除 + gsettings を既定に戻す
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
  [[ -z "$only" ]] && steps=(fingerprint pam)

  for step in "${steps[@]}"; do
    case "$step" in
      fingerprint)
        if [[ -d /usr/local/src/lifebook-libfprint-installer/libfprint/builddir ]]; then
          log "Running ninja uninstall"
          ( cd /usr/local/src/lifebook-libfprint-installer/libfprint && \
            ninja -C builddir uninstall ) || true
        fi
        rm -f /usr/local/lib/x86_64-linux-gnu/libfprint-2.so*
        rm -f /usr/local/lib/fprint-2/*
        ldconfig
        systemctl restart fprintd
        ok "removed custom libfprint"
        ;;
      pam)
        if [[ -f /etc/pam.d/gdm-password ]]; then
          # 新形式と旧 sufficient 行の両方を削除
          sed -i '/^auth    \[success=1 default=ignore\] pam_fprintd\.so$/d' /etc/pam.d/gdm-password
          sed -i '/^auth    sufficient      pam_fprintd\.so$/d' /etc/pam.d/gdm-password
          ok "removed pam_fprintd.so line(s)"
        fi
        local user="${SUDO_USER:-}"
        if [[ -n "$user" ]] && command -v gsettings >/dev/null 2>&1; then
          sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus" \
            gsettings reset org.gnome.control-center.user-accounts show-fingerprint 2>/dev/null || true
        fi
        ok "reset show-fingerprint gsettings"
        ;;
      all) ;;
      *) die "Unknown step: $step" ;;
    esac
  done
}

main "$@"
