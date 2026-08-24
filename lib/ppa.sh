# ppa.sh — 任意 PPA 追加 (brave / vscodium / nodesource / charm)

ppa_step() {
  local dry="$1"
  [[ "$dry" == "1" ]] && SETUP_DRY=1 || SETUP_DRY=0

  if [[ "${SETUP_EXTRA_PPAS:-1}" == "0" ]]; then
    log "Extra PPAs disabled (SETUP_EXTRA_PPAS=0)"
    return 0
  fi

  step "Adding third-party repositories"

  # 1) Brave Browser
  if [[ ! -f /etc/apt/sources.list.d/brave-browser-release.sources ]] \
     && [[ ! -f /etc/apt/sources.list.d/brave-browser-release.list ]]; then
    log "Adding Brave browser PPA"
    run apt-get install -y curl
    run bash -c "curl -fsSLo /etc/apt/keyrings/brave-browser-release.asc https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"
    run bash -c "echo \"deb [signed-by=/etc/apt/keyrings/brave-browser-release.asc] https://brave-browser-apt-release.s3.brave.com/ stable main\" > /etc/apt/sources.list.d/brave-browser-release.list"
  fi

  # 2) VSCodium
  if [[ ! -f /etc/apt/sources.list.d/vscodium.list ]]; then
    log "Adding VSCodium PPA"
    run bash -c "wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/vscodium.gpg"
    run bash -c "echo \"deb [signed-by=/etc/apt/keyrings/vscodium.gpg] https://download.vscodium.com/debs vscodium main\" > /etc/apt/sources.list.d/vscodium.list"
  fi

  # 3) NodeSource (Node 22 LTS)
  if [[ ! -f /etc/apt/sources.list.d/nodesource.list ]]; then
    log "Adding NodeSource (Node 22 LTS) PPA"
    run bash -c "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg"
    run bash -c "echo \"deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main\" > /etc/apt/sources.list.d/nodesource.list"
  fi

  # 4) Charm (Crush)
  if [[ ! -f /etc/apt/sources.list.d/charm.list ]]; then
    log "Adding Charm PPA"
    run bash -c "curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/charm.gpg"
    run bash -c "echo \"deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt * main\" > /etc/apt/sources.list.d/charm.list"
  fi

  step "apt-get update after PPA additions"
  run apt-get update -y
}