# u9310_fingerprint_activate

Script de configuración de un solo propósito para activar el **sensor de huellas NB-2033-U** de la serie Fujitsu LIFEBOOK U9310 (incluidos U9311 / U9312) en Ubuntu 24.04+.

## Entornos compatibles

- Ubuntu 24.04 / 24.10 / 25.04 / 26.04 (resolute)
- Sensor de huellas: NEXT Biometrics **NB-2033-U** (USB ID `298d:2033`)
- Comando de verificación: `lsusb | grep "298d:2033"`

## Pasos incluidos

| Paso | Descripción |
|---|---|
| `fingerprint` | Compila fprintd + libfprint (MR !574) e instala en `/usr/local` |
| `pam` | Inserta `pam_fprintd.so` en `/etc/pam.d/gdm-password` y activa `show-fingerprint` en `gsettings` |

> Este repositorio se enfoca **solo** en la configuración de la huella dactilar. Las configuraciones auxiliares (apt upgrade / PPA / Tailscale / crush) se gestionan en repositorios separados.

## Uso

```sh
git clone https://github.com/walhalax/u9310_fingerprint_activate.git
cd u9310_fingerprint_activate
sudo ./setup.sh --yes
```

Después de ejecutar:

1. **Registre su huella**: Configuración → Usuarios → su usuario → Huella digital → "+" → 5 escaneos
2. **Pruebe en la pantalla de GDM**: Cierre sesión y verifique que aparezca "Coloque el dedo" en la pantalla de inicio

### Selección de pasos

```sh
sudo ./setup.sh --only fingerprint --yes
sudo ./setup.sh --only pam --yes
sudo ./setup.sh --dry-run
```

### Desinstalación

```sh
sudo ./uninstall.sh --yes
```

## Detalles técnicos

- `libfprint` oficial aún no soporta NB-2033-U. Este script compila e instala en `/usr/local` un fork con el parche del MR !574 (en revisión) → coexiste con la versión apt (`/usr/local/lib` tiene prioridad, por lo que `fprintd` carga la versión propia)
- `fprintd` carga automáticamente la libfprint del fork y abre el dispositivo con el driver `nb2033`
- Inserta `auth sufficient pam_fprintd.so` antes de `@include common-auth` en `/etc/pam.d/gdm-password` → si la huella coincide, inicia sesión de inmediato; si falla, recae al método de contraseña
- Activa `org.gnome.control-center.user-accounts show-fingerprint` en `gsettings` para mostrar el menú de huella en Configuración de GNOME

## Principios de diseño

- **Un solo propósito**: centrado exclusivamente en la huella dactilar
- **Idempotencia**: cada paso puede ejecutarse varias veces sin efectos secundarios
- **DRY-RUN**: previsualice todo el proceso con `--dry-run`
- **Reversión granular**: `uninstall.sh --only fingerprint` para revertir un paso específico

## Licencia

MIT

## Enlaces relacionados

- lifebook-libfprint-installer: https://github.com/suikan4github/lifebook-libfprint-installer
- libfprint MR !574 (NB-2033-U): https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/574