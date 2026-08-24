# apt.sh — apt update / upgrade / phased-updates 制御

apt_step() {
  local dry="$1"
  [[ "$dry" == "1" ]] && SETUP_DRY=1 || SETUP_DRY=0

  step "apt update"
  run apt-get update -y

  step "apt upgrade (phased-updates forced)"
  local phased_flag="-o APT::Get::Always-Include-Phased-Updates=true"
  run apt-get upgrade -y "$phased_flag"

  step "apt autoremove"
  run apt-get autoremove -y

  step "Configuring phased-updates"
  # apt config drop-in で永続化
  local conf_dir="/etc/apt/apt.conf.d"
  local conf_file="$conf_dir/99no-phased-updates"
  if [[ ! -f "$conf_file" ]] && [[ "${SETUP_PHASED:-1}" != "0" ]]; then
    log "Pinning phased-updates off permanently at $conf_file"
    [[ "$dry" != "1" ]] && cat > "$conf_file" <<'EOF'
// Always include phased updates so security/critical updates aren't held back.
APT::Get::Always-Include-Phased-Updates "true";
EOF
  fi
}

# utility: パッケージがインストール済みか
pkg_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}