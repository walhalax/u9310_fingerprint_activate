# u9310_fingerprint_activate

用于在 Ubuntu 24.04+ 上激活 Fujitsu LIFEBOOK U9310 系列(包括 U9311 / U9312)**NB-2033-U 指纹传感器** 的单一目的安装脚本。

## 支持的环境

- Ubuntu 24.04 / 24.10 / 25.04 / 26.04 (resolute)
- 搭载指纹传感器: NEXT Biometrics **NB-2033-U** (USB ID `298d:2033`)
- 验证命令: `lsusb | grep "298d:2033"`

## 包含的步骤

| 步骤 | 内容 |
|---|---|
| `fingerprint` | 构建 fprintd + libfprint (MR !574) 并安装到 `/usr/local` |
| `pam` | 在 `/etc/pam.d/gdm-password` 插入 `pam_fprintd.so`，并启用 gsettings 的 `show-fingerprint` |

> 本仓库**仅**关注指纹设置。apt 升级 / PPA 添加 / Tailscale / crush 等周边配置在单独的仓库中处理。

## 使用方法

```sh
git clone https://github.com/walhalax/u9310_fingerprint_activate.git
cd u9310_fingerprint_activate
sudo ./setup.sh --yes
```

执行后的流程:

1. **注册指纹**: 设置 → 用户 → 您的用户 → 指纹 → "+" → 扫描 5 次
2. **在 GDM 登录界面测试**: 注销后，检查登录界面是否显示"请放置手指"

### 指定步骤

```sh
sudo ./setup.sh --only fingerprint --yes
sudo ./setup.sh --only pam --yes
sudo ./setup.sh --dry-run
```

### 卸载

```sh
sudo ./uninstall.sh --yes
```

## 技术细节

- `libfprint` 官方尚未支持 NB-2033-U。此脚本将带有 MR !574 补丁(审查中)的 fork 构建并安装到 `/usr/local` → 与 apt 版本共存(`/usr/local/lib` 优先，因此 `fprintd` 加载自定义版本)
- `fprintd` 自动加载 fork 版 libfprint，并使用 `nb2033` 驱动打开设备
- 在 `/etc/pam.d/gdm-password` 的 `@include common-auth` 之前插入 `auth sufficient pam_fprintd.so` → 指纹匹配成功立即登录；失败则回退到密码
- 将 gsettings 的 `org.gnome.control-center.user-accounts show-fingerprint` 设为 `true`，在 GNOME 设置中显示指纹菜单

## 设计原则

- **单一目的**: 专注于指纹设置
- **幂等性**: 每个步骤可以多次执行而不会产生副作用
- **DRY-RUN**: 使用 `--dry-run` 预览整个流程
- **细粒度回滚**: 通过 `uninstall.sh --only fingerprint` 等命令精确还原

## 许可证

MIT

## 相关链接

- lifebook-libfprint-installer: https://github.com/suikan4github/lifebook-libfprint-installer
- libfprint MR !574 (NB-2033-U): https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/574