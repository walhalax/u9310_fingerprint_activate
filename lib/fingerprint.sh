# fingerprint.sh — fprintd + libfprint (NB-2033-U 暫定対応) 導入

readonly FPRINT_INSTALLER_REPO="https://github.com/suikan4github/lifebook-libfprint-installer.git"
readonly FPRINT_INSTALLER_DIR="/usr/local/src/lifebook-libfprint-installer"

fingerprint_step() {
  local dry="$1"
  [[ "$dry" == "1" ]] && SETUP_DRY=1 || SETUP_DRY=0

  step "Installing build dependencies"
  run apt-get install -y \
    build-essential cmake git pkg-config meson ninja-build \
    libglib2.0-dev libgusb-dev libnss3-dev libgudev-1.0-dev \
    libpixman-1-dev libgirepository1.0-dev \
    libfprint-2-2 libfprint-2-dev fprintd libpam-fprintd \
    libssl-dev systemd-dev

  step "Cloning lifebook-libfprint-installer"
  if [[ ! -d "$FPRINT_INSTALLER_DIR" ]]; then
    run git clone "$FPRINT_INSTALLER_REPO" "$FPRINT_INSTALLER_DIR"
  else
    log "Already cloned: $FPRINT_INSTALLER_DIR"
  fi

  step "Building libfprint with NB-2033-U patch"
  run bash -c "cd '$FPRINT_INSTALLER_DIR' && ./lifebook-libfprint-installer.sh"

  step "Restarting fprintd"
  run systemctl restart fprintd
  sleep 1
  run fprintd-list 2>/dev/null || warn "fprintd-list returned no devices"
}

# 既存登録のクリーンアップ用
fingerprint_reset() {
  local user="${1:-${SUDO_USER:-}}"
  [[ -z "$user" ]] && die "fingerprint_reset: username required"
  log "Deleting enrolled fingers for $user"
  for finger in left-thumb left-index-finger left-middle-finger left-ring-finger left-little-finger \
                right-thumb right-index-finger right-middle-finger right-ring-finger right-little-finger; do
    fprintd-delete "$user" 2>/dev/null || true
  done
}