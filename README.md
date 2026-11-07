# AmneziaWG LegacyAndroid Port

Порт Android-клиента [AmneziaWG](https://amnezia.org/learn-more/31_amneziawg) для Android 4.4.4+
(KitKat, API 19). Туннель работает только в userspace через `amneziawg-go`; root и ядерный
модуль не используются.

## Что изменено для legacy-порта

- Единственный backend — `GoBackend` (userspace). `AwgQuickBackend`, `awg-quick`, `libwg.so`
  и root-shell удалены.
- `minSdk = 19`, `targetSdk = 36`, собирается только `armeabi-v7a`.
- Foreground-уведомление VPN-сервиса: без action-кнопок, с каналом на API 26+ и обычным
  `Notification.Builder` на KitKat.
- Для API 19 обойдены отсутствующие методы `VpnService.Builder`:
  `addAllowedApplication`, `addDisallowedApplication`, `addSearchDomain`, `allowFamily`,
  `setBlocking`. Блокирующий режим TUN на KitKat выставляется через JNI.
- Java 8 API (`Optional`, `java.time`, streams) покрыты core library desugaring.
- NDK r26b собирает Go c-shared библиотеку с target triple API 19; Go-рантайм патчится
  на `CLOCK_BOOTTIME` через `-overlay` (аналог старого патча без `patch(1)`).

## Требования

- JDK 17
- Android SDK: platform 36, build-tools 36.0.0, NDK 25.2.9519653 (r25c), CMake 3.22.1
- Go 1.25+
- Linux/macOS или Windows с `cmd`/PowerShell; `make`, `flock` и `patch` больше не нужны

## Сборка

```sh
./gradlew assembleDebug
```

APK: `ui/build/outputs/apk/debug/ui-debug.apk`.

Для release-AAB используйте `./gradlew bundleRelease` (нужна подпись). CI-workflow
`.github/workflows/build.yml` собирает debug APK или signed AAB.
