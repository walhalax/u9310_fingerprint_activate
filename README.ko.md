# u9310_fingerprint_activate

Fujitsu LIFEBOOK U9310 시리즈(U9311 / U9312 포함)의 **NB-2033-U 지문 센서**를 Ubuntu 24.04+에서 활성화하기 위한 단일 목적 설치 스크립트입니다.

## 지원 환경

- Ubuntu 24.04 / 24.10 / 25.04 / 26.04 (resolute)
- 탑재 지문 센서: NEXT Biometrics **NB-2033-U** (USB ID `298d:2033`)
- 확인 명령: `lsusb | grep "298d:2033"`

## 포함된 단계

| 단계 | 내용 |
|---|---|
| `fingerprint` | fprintd + libfprint (MR !574)을 빌드하여 `/usr/local`에 설치 |
| `pam` | `/etc/pam.d/gdm-password`에 `pam_fprintd.so`를 삽입하고 gsettings의 `show-fingerprint` 활성화 |

> 이 저장소는 지문 설정**만** 다룹니다. apt 업그레이드 / PPA 추가 / Tailscale / crush 등의 주변 설정은 별도의 저장소에서 처리합니다.

## 사용 방법

```sh
git clone https://github.com/walhalax/u9310_fingerprint_activate.git
cd u9310_fingerprint_activate
sudo ./setup.sh --yes
```

실행 후 절차:

1. **지문 등록**: 설정 → 사용자 → 본인 사용자 → 지문 → "+" → 5회 스캔
2. **GDM 로그인 화면에서 테스트**: 로그아웃 후 로그인 화면에 "손가락을 올려주세요"가 표시되는지 확인

### 단계 지정

```sh
sudo ./setup.sh --only fingerprint --yes
sudo ./setup.sh --only pam --yes
sudo ./setup.sh --dry-run
```

### 제거

```sh
sudo ./uninstall.sh --yes
```

## 기술 세부 사항

- 공식 `libfprint`은 NB-2033-U를 아직 지원하지 않습니다. 이 스크립트는 MR !574 패치(리뷰 중)가 포함된 fork를 `/usr/local`에 빌드 및 설치 → apt 버전과 공존(`/usr/local/lib`이 우선하므로 `fprintd`는 자체 버전을 로드)
- `fprintd`는 fork 버전 libfprint를 자동으로 로드하고 `nb2033` 드라이버로 장치를 엽니다
- `/etc/pam.d/gdm-password`의 `@include common-auth` 앞에 `auth sufficient pam_fprintd.so`를 삽입 → 지문 매칭 성공 시 즉시 로그인, 실패 시 비밀번호로 폴백
- gsettings의 `org.gnome.control-center.user-accounts show-fingerprint`를 `true`로 설정하여 GNOME 설정에 지문 메뉴를 표시

## 설계 원칙

- **단일 목적**: 지문 설정에만 집중
- **멱등성**: 각 단계는 여러 번 실행해도 부작용 없음
- **DRY-RUN**: `--dry-run`으로 전체 흐름 미리보기
- **세분화된 롤백**: `uninstall.sh --only fingerprint` 등으로 특정 단계만 정확히 되돌림

## 라이선스

MIT

## 관련 링크

- lifebook-libfprint-installer: https://github.com/suikan4github/lifebook-libfprint-installer
- libfprint MR !574 (NB-2033-U): https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/574