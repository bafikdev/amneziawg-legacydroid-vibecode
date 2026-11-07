# AmneziaWG LegacyAndroid Port

Порт Android-клиента [AmneziaWG](https://amnezia.org/learn-more/31_amneziawg) для Android 5 и выше 
> так же поддерживает Android 4.4.4+, но требуется рутировать устройство и обновить сертификаты из за лимитов VpnService

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

> Сделанно через Vibecode используя Deepseek Harness и немного Qwen Code в любительских целях
