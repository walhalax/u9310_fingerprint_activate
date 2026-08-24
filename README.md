# u9310_fingerprint_activate

Fujitsu LIFEBOOK U9310 シリーズ (U9311 / U9312 を含む) の **NB-2033-U 指紋センサー** を Ubuntu 24.04+ で使えるようにする、単一目的のセットアップスクリプトです。

## 対象環境

- Ubuntu 24.04 / 24.10 / 25.04 / 26.04 (resolute)
- 搭載指紋センサー: NEXT Biometrics **NB-2033-U** (USB ID `298d:2033`)
- 確認コマンド: `lsusb | grep "298d:2033"`

## 含まれるステップ

| ステップ | 内容 |
|---|---|
| `fingerprint` | fprintd + libfprint (MR !574) をビルドし `/usr/local` にインストール |
| `pam` | `/etc/pam.d/gdm-password` に `pam_fprintd.so` を挿入、`gsettings` の `show-fingerprint` を有効化 |

> このリポジトリは指紋セットアップ **だけ** に絞っています。apt upgrade / PPA 追加 / Tailscale / crush 等の周辺セットアップは別リポジトリで扱う想定です。

## 使い方

```sh
git clone https://github.com/walhalax/u9310_fingerprint_activate.git
cd u9310_fingerprint_activate
sudo ./setup.sh --yes
```

実行後の流れ:

1. **指紋を登録**: Settings → Users → 自分のユーザー → Fingerprint → 「+」→ 5回スキャン
2. **GDM ログイン画面でテスト**: ログアウト後、サインイン画面で「Place finger」表示が出るか確認

### ステップ指定

```sh
# ライブラリだけ先にビルド
sudo ./setup.sh --only fingerprint --yes

# PAM をあとで設定
sudo ./setup.sh --only pam --yes

# ドライラン (実際には変更しない)
sudo ./setup.sh --dry-run
```

### アンインストール

```sh
sudo ./uninstall.sh --yes
```

## 何をしているか(技術詳細)

- `libfprint` 公式は NB-2033-U 未対応。MR !574 のレビュー中パッチを取り込んだフォークを `/usr/local` にビルド・配置 → 既存 apt 版と共存(`/usr/local/lib` が優先されるため `fprintd` が自家版を掴む)
- `fprintd` はフォーク版 libfprint を自動ロードし、`nb2033` ドライバでデバイスを開く
- `/etc/pam.d/gdm-password` の `@include common-auth` の前に `auth sufficient pam_fprintd.so` を挿入 → 指紋成功で即ログイン、失敗時は password にフォールバック
- gsettings `org.gnome.control-center.user-accounts show-fingerprint` を `true` にして GNOME 設定画面に指紋メニューを表示

## 設計方針

- **単一目的**: 指紋セットアップだけに絞り、責務を明確化
- **冪等性**: 各ステップは何度実行しても副作用が出ない
- **DRY-RUN**: `--dry-run` で全工程をプレビュー
- **部分巻き戻し**: `uninstall.sh --only fingerprint` 等でピンポイント復元

## ライセンス

MIT

## 関連リンク

- lifebook-libfprint-installer: https://github.com/suikan4github/lifebook-libfprint-installer
- libfprint MR !574 (NB-2033-U): https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/574