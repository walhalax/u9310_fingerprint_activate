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
| `pam` | Inserts `pam_fprintd.so` into `/etc/pam.d/gdm-password` (in `[success=1 default=ignore]` form) and enables `show-fingerprint` in gsettings |

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
- The script inserts `auth [success=1 default=ignore] pam_fprintd.so` before `@include common-auth` in `/etc/pam.d/gdm-password`:
  - Fingerprint success → next module (`common-auth`, the password stack) is skipped by 1 → login succeeds
  - Fingerprint failure / timeout → PAM is **not** marked as failed; control falls back to `common-auth` so the password prompt appears
  - This lets you type the password while a finger is on the sensor: if the print matches, you log in immediately; otherwise the password takes over
- A legacy `auth sufficient pam_fprintd.so` line, if present, is auto-migrated to the new form on the next run of `setup.sh --only pam --yes`
- gsettings `org.gnome.control-center.user-accounts show-fingerprint` is set to `true` so the GNOME settings panel shows the fingerprint menu

## Tips & troubleshooting

### Finger placement on NB-2033-U (sensor quirks)

NB-2033-U is a small, **contact-type** swipe sensor. Reliability depends heavily on how you place your finger:

- Register the **fingerprint you actually use** for login (e.g. right index). Re-enrollment is fine — wipe the existing entry first with `fprintd-delete "$USER"`.
- Cover the **entire sensing strip** with the whorl/center of your fingertip. The first phalanx must fully overlap the sensor.
- Keep the finger **flat**, not tilted. Light pressure is enough — pressing harder smears the print and increases failure rate.
- The sensor is sensitive to skin moisture: very dry or very sweaty fingers both fail. If you repeatedly fail, clean the strip with a dry microfiber cloth.
- Register the **same finger twice** (or two fingers) as a fallback. `fprintd-list "$USER"` shows enrolled entries as `(press)` when the cache password is empty.

### "Authentication required" prompt right after the fingerprint step

If GDM pops up a polkit-style **"Authentication required"** dialog *after* the fingerprint is accepted, the cause is almost always the GNOME **login keyring** (`gkr-pam`) not matching your login password. Symptoms in `/var/log/auth.log`:

```
gdm-password]: gkr-pam: couldn't unlock the login keyring.
```

Fix — pick whichever matches your situation:

1. **The login keyring password matches the login password** (most common after a manual password change):
   - `seahorse` → "Login" → right-click → "Change password" → enter the current login password twice.
   - Or, from CLI, if no secrets are stored:
     ```sh
     mv ~/.local/share/keyrings/login.keyring ~/.local/share/keyrings/login.keyring.bak
     # log out and back in — a fresh empty keyring is created automatically
     ```
2. **You switched login methods recently** (e.g. you removed `pam_fprintd.so`, or changed `sufficient` to `[success=1 default=ignore]`): the cached `fprintd` password is gone, so GDM cannot unlock the keyring. Force the password path and re-unlock once with the CLI:
   ```sh
   loginctl terminate-session "$XDG_SESSION_ID"
   # log in with password on GDM; the keyring will prompt for the password
   ```

### Verifying the PAM line is correct

After `setup.sh --only pam --yes`, `/etc/pam.d/gdm-password` should contain **exactly**:

```
auth    [success=1 default=ignore] pam_fprintd.so
```

placed **above** `@include common-auth`. If the line uses the legacy `sufficient` form, re-run `sudo ./setup.sh --only pam --yes` — the script auto-migrates it.

### Rollback

`./uninstall.sh --only pam --yes` removes **both** the new and the legacy form of the line, so the file returns to its pre-setup state (modulo any `.bak.*` snapshot).

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