# SummaMove mobile

Flutter-source voor de read-only health-syncdemo.

## Flow

1. Login bij Laravel en bewaar Sanctum-token in `flutter_secure_storage`.
2. Kies precies één actieve bron voor het toestel.
3. Vraag expliciet read-permissions.
4. Lees wijzigingen via een `HealthSourceAdapter`.
5. Normaliseer naar het Laravel-contract en synchroniseer handmatig.
6. Toon syncresultaat en dagoverzicht.

De mock-adapter werkt zonder native SDK. Health Connect, HealthKit en Samsung Health gebruiken hetzelfde MethodChannel-contract in `docs/native-bridge-contract.md`.

## Lokale toolchain

De Windows-ontwikkelmachine is ingericht met:

- Flutter stable en meegeleverde Dart SDK.
- Android Studio.
- Android SDK-platforms 34, 35 en 36.
- Platform-tools, build-tools 36, NDK 28.2, CMake 3.22 en Android Emulator.
- Pixel 7 AVD `SummaMove_API_36`.

## Lokaal draaien

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter emulators --launch SummaMove_API_36
flutter run
```

De standaard emulator-API-URL is `http://10.0.2.2:8001/api/v1`. Start Laravel vanaf de repository-root met:

```powershell
php artisan serve --host=0.0.0.0 --port=8001
```

De Android- en iOS-projectbestanden zijn gegenereerd. Sluit als volgende implementatiestap de native MethodChannel-hostbridges aan volgens het contract. HealthKit vereist Mac/Xcode; Samsung Health vereist de vendor SDK en developer mode.
