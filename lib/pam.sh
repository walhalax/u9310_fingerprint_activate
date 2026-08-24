# pam.sh — /etc/pam.d/gdm-password と gsettings の冪等設定

PAM_GDM_PASSWORD="/etc/pam.d/gdm-password"
readonly PAM_GDM_PASSWORD
readonly PAM_FPRINTD_LINE='auth    sufficient      pam_fprintd.so'
readonly GSETTINGS_SCHEMA="org.gnome.control-center.user-accounts"
readonly GSETTINGS_KEY="show-fingerprint"

pam_step() {
  local dry="$1"
  [[ "$dry" == "1" ]] && SETUP_DRY=1 || SETUP_DRY=0

  local user="${SUDO_USER:-}"

  step "Configuring /etc/pam.d/gdm-password"
  if [[ -f "$PAM_GDM_PASSWORD" ]] && ! grep -q "^${PAM_FPRINTD_LINE// / }" "$PAM_GDM_PASSWORD" 2>/dev/null \
     && ! grep -qF "$PAM_FPRINTD_LINE" "$PAM_GDM_PASSWORD"; then
    log "Inserting '$PAM_FPRINTD_LINE' before @include common-auth"
    if [[ "$dry" != "1" ]]; then
      cp "$PAM_GDM_PASSWORD" "${PAM_GDM_PASSWORD}.bak.$(date +%Y%m%d%H%M%S)"
      sed -i "\|^@include common-auth|i\\$PAM_FPRINTD_LINE" "$PAM_GDM_PASSWORD"
    fi
  else
    log "PAM already configured or missing"
  fi

  step "Configuring gsettings (show-fingerprint)"
  if [[ -n "$user" ]] && command -v gsettings >/dev/null 2>&1; then
    local current
    current="$(sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus" \
                gsettings get "$GSETTINGS_SCHEMA" "$GSETTINGS_KEY" 2>/dev/null || echo "unknown")"
    log "Current value: $current"
    if [[ "$current" != "true" ]]; then
      log "Enabling $GSETTINGS_KEY for $user"
      [[ "$dry" != "1" ]] && \
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus" \
          gsettings set "$GSETTINGS_SCHEMA" "$GSETTINGS_KEY" true
    fi
  else
    warn "No SUDO_USER or gsettings not available; skip gsettings step"
  fi
}