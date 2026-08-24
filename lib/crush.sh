# crush.sh — crush (charm CLI) + グローバル設定

readonly CRUSH_RC_PATH="${HOME}/.config/crush/crushrc"
readonly CRUSH_GLOBAL_NOTES_PATH="${HOME}/crush/setting.md"
readonly CRUSH_PPA_PKG="crush"

crush_step() {
  local dry="$1"
  [[ "$dry" == "1" ]] && SETUP_DRY=1 || SETUP_DRY=0

  local user="${SUDO_USER:-}"
  [[ -z "$user" ]] && die "crush_step: SUDO_USER required"

  step "Installing crush from PPA"
  run apt-get install -y "$CRUSH_PPA_PKG"

  step "Writing global crushrc"
  local user_home
  user_home="$(getent passwd "$user" | cut -d: -f6)"
  [[ -z "$user_home" ]] && die "Cannot resolve home for $user"
  local rc_dir rc_path notes_dir notes_path
  rc_dir="$(dirname "$CRUSH_RC_PATH")"
  rc_path="$user_home$(echo "$CRUSH_RC_PATH" | sed "s|^$HOME||")"
  notes_dir="$user_home/crush"
  notes_path="$user_home/crush/setting.md"

  if [[ ! -f "$rc_path" ]]; then
    log "Writing $rc_path"
    [[ "$dry" != "1" ]] && \
      install -d -m 0755 -o "$user" -g "$user" "$rc_dir" && \
      tee "$rc_path" >/dev/null <<EOF
# Global crushrc — sourced from $CRUSH_RC_PATH
CRUSH_HOME="\$HOME/crush"
export CRUSH_PROJECT_DIR="\$CRUSH_HOME"

[[ -d "\$CRUSH_HOME" ]] || mkdir -p "\$CRUSH_HOME"

# Inject the global settings note into every session's context.
if [[ -f "\$CRUSH_HOME/setting.md" ]]; then
  option global-context-path "\$CRUSH_HOME/setting.md"
fi
EOF
    [[ "$dry" != "1" ]] && chown "$user:$user" "$rc_path" && chmod 0644 "$rc_path"
  else
    log "$rc_path already exists; skipping"
  fi

  step "Writing global setting.md"
  if [[ ! -f "$notes_path" ]]; then
    log "Writing $notes_path"
    [[ "$dry" != "1" ]] && \
      install -d -m 0755 -o "$user" -g "$user" "$notes_dir" && \
      tee "$notes_path" >/dev/null <<'EOF'
# Crush グローバル設定

## 言語
- **すべて日本語ベースで回答する**
  - ユーザーへの返信、エラーメッセージの説明、手順の説明など、すべてのテキスト出力を日本語で行う
  - 固有名詞・コマンド名・コード識別子は原文のまま英語を維持する
EOF
    [[ "$dry" != "1" ]] && chown "$user:$user" "$notes_path"
  else
    log "$notes_path already exists; skipping"
  fi
}