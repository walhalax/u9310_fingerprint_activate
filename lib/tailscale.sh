# tailscale.sh — Tailscale インストール (TS_AUTHKEY 必須)

tailscale_step() {
  local dry="$1"
  [[ "$dry" == "1" ]] && SETUP_DRY=1 || SETUP_DRY=0

  if [[ -z "${TS_AUTHKEY:-}" ]]; then
    warn "TS_AUTHKEY not set; skipping Tailscale. Set TS_AUTHKEY in ~/.config/u9310_fingerprint_activate/env to enable."
    return 0
  fi

  step "Installing Tailscale via official install.sh"
  local script="/tmp/tailscale-install.sh"
  if [[ ! -f "$script" ]]; then
    run curl -fsSL -o "$script" https://tailscale.com/install.sh
  fi
  run sh "$script"

  step "Authenticating to tailnet"
  run tailscale up --authkey="$TS_AUTHKEY"
  run tailscale status
}