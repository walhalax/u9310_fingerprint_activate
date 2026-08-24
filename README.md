# u9310_fingerprint_activate

Lifebook U9300 / U9311 / U9312 を Ubuntu 24.04+ で初期セットアップするための再現性あるセットアップスクリプト集。

## 含まれる内容

| ステップ | 内容 |
|---|---|
| `apt` | `apt update/upgrade`(phased-updates 強制) + `autoremove` + 設定永続化 |
| `ppa` | Brave / VSCodium / NodeSource / Charm の追加 |
| `fingerprint` | NEXT Biometrics NB-2033-U 対応 libfprint (MR !574) と fprintd の導入 |
| `pam` | `/etc/pam.d/gdm-password` に `pam_fprintd.so` を挿入、`gsettings` の `show-fingerprint` を有効化 |
| `crush` | crush (charm CLI) + `~/.config/crush/crushrc` + グローバル `setting.md` |
| `tailscale` | Tailscale 公式 install.sh 実行 (要 `TS_AUTHKEY`) |

## 使い方

```sh
git clone https://github.com/<your-account>/u9310_fingerprint_activate.git
cd u9310_fingerprint_activate
sudo cp env.example ~/.config/u9310_fingerprint_activate/env
sudo $EDITOR ~/.config/u9310_fingerprint_activate/env   # TS_AUTHKEY など
chmod 600 ~/.config/u9310_fingerprint_activate/env
sudo ./setup.sh --yes
```

### ステップ指定

```sh
# 指紋関連だけ実行
sudo ./setup.sh --only fingerprint,pam --yes

# tailscale をスキップして実行
sudo ./setup.sh --skip tailscale

# ドライラン (実際には変更しない)
sudo ./setup.sh --dry-run
```

### アンインストール

```sh
sudo ./uninstall.sh --only fingerprint,pam
sudo ./uninstall.sh --yes   # 全削除
```

## 対応環境

- Ubuntu 24.04 / 24.10 / 25.04 / 26.04 (resolute)
- Fujitsu LIFEBOOK U9311 / U9312(U9300 は同等構成で動作する想定)
- NEXT Biometrics NB-2033-U (USB ID 298d:2033) 搭載モデル

> ⚠️ libfprint の NB-2033-U ドライバは MR !574 のレビュー中コードです。`/usr/local` に上書きビルドするため、本家の libfprint と共存します。本家に取り込まれたあとは `uninstall.sh --only fingerprint` で巻き戻し、apt のみで運用して下さい。

## 設計方針

- **冪等性**: 同じステップを 2 度実行しても副作用が出ないようにチェックする
- **DRY-RUN**: `--dry-run` で全工程をプレビュー
- **段階的ロールバック**: `uninstall.sh --only` で部分巻き戻し可能
- **コードレス・シークレット**: API キーは `~/.config/u9310_fingerprint_activate/env` に集約(gitignore 対象)

## ライセンス

MIT

## 関連リンク

- lifebook-libfprint-installer: https://github.com/suikan4github/lifebook-libfprint-installer
- libfprint MR !574 (NB-2033-U): https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/574
- Tailscale: https://tailscale.com/download/linux
- Crush: https://charm.land/crush