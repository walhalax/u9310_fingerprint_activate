# u9310_fingerprint_activate

A single-purpose setup script to enable the **NB-2033-U fingerprint sensor** on Fujitsu LIFEBOOK U9310 series (including U9311 / U9312) on Ubuntu 24.04+.

## Supported environments

- Ubuntu 24.04 / 24.10 / 25.04 / 26.04 (resolute)
- Sensor: NEXT Biometrics **NB-2033-U** (USB ID `298d:2033`)
- Verify: `lsusb | grep "298d:2033"`

## Steps

| Step | Description |
|---|---|
| `fingerprint` | Builds fprintd + libfprint (MR !574) and installs to `/usr/local` |
| `pam` | Inserts `pam_fprintd.so` into `/etc/pam.d/gdm-password` and enables `show-fingerprint` in gsettings |

> This repository focuses **only** on fingerprint setup. Surrounding setup (apt upgrade / PPA / Tailscale / crush) lives in separate repositories.

## Usage

```sh
git clone https://github.com/walhalax/u9310_fingerprint_activate.git
cd u9310_fingerprint_activate
sudo ./setup.sh --yes
```

After running:

1. **Enroll a fingerprint**: Settings → Users → your user → Fingerprint → "+" → 5 scans
2. **Test on GDM**: log out and check that "Place finger" appears on the sign-in screen

### Step selection

```sh
sudo ./setup.sh --only fingerprint --yes
sudo ./setup.sh --only pam --yes
sudo ./setup.sh --dry-run
```

### Uninstallation

```sh
sudo ./uninstall.sh --yes
```

## Technical details

- Official `libfprint` does not yet support NB-2033-U. This script builds and installs the MR !574 fork (in review) to `/usr/local` — it coexists with the apt version (`/usr/local/lib` takes precedence, so `fprintd` loads the custom build)
- `fprintd` auto-loads the fork libfprint and opens the device with the `nb2033` driver
- The script inserts `auth sufficient pam_fprintd.so` before `@include common-auth` in `/etc/pam.d/gdm-password` → fingerprint success logs in immediately; failure falls back to password
- gsettings `org.gnome.control-center.user-accounts show-fingerprint` is set to `true` so the GNOME settings panel shows the fingerprint menu

## Multilingual documentation

- 🇯🇵 [日本語 (Japanese)](README.ja.md)
- 🇪🇸 [Español (Spanish)](README.es.md)
- 🇨🇳 [中文 (Simplified Chinese)](README.zh.md)
- 🇰🇷 [한국어 (Korean)](README.ko.md)

## Design principles

- **Single purpose**: focus exclusively on fingerprint setup
- **Idempotent**: each step can run multiple times without side effects
- **DRY-RUN**: preview the full workflow with `--dry-run`
- **Granular rollback**: `uninstall.sh --only fingerprint` for precise per-step revert

## License

MIT

## Related links

- lifebook-libfprint-installer: https://github.com/suikan4github/lifebook-libfprint-installer
- libfprint MR !574 (NB-2033-U): https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/574