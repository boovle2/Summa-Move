# SummaMove mobile

Dit is de Flutter-app van SummaMove. Flutter bouwt de schermen en Dart bevat de app-logica. Laravel blijft verantwoordelijk voor login, data, challenges, punten en adminacties.

## Mappen

```text
lib/main.dart                 app-start, routing en thema
lib/src/screens/              schermen
lib/src/services/             API-client, repositories en sync-service
lib/src/health/               health-adapters
android/                      Android hostcode en Health Connect bridge
ios/                          iOS projectbasis
test/                         Flutter tests
```

## API-url per build

Gebruik altijd een `--dart-define=API_BASE_URL=...` bij een demo-build.

| Doel | API-url |
|---|---|
| Android Emulator | `http://10.0.2.2:8001/api/v1` |
| Echte Android telefoon op dezelfde Wi-Fi | `http://192.168.178.109:8001/api/v1` |
| USB fallback met adb reverse | `http://127.0.0.1:8001/api/v1` |

Voor Wi-Fi moet Laravel draaien met:

```powershell
php artisan serve --host=0.0.0.0 --port=8001
```

Voor USB fallback:

```powershell
adb reverse tcp:8001 tcp:8001
```

## APK bouwen

Vanaf `C:\Users\zakel\Laravel\SummaMove\mobile`:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.178.109:8001/api/v1
Copy-Item build\app\outputs\flutter-apk\app-release.apk ..\release-apks\SummaMove-android-real-device.apk -Force

flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1
Copy-Item build\app\outputs\flutter-apk\app-release.apk ..\release-apks\SummaMove-android-emulator.apk -Force
```

Installeer op een aangesloten Android telefoon:

```powershell
adb install -r ..\release-apks\SummaMove-android-real-device.apk
```

## Health Connect flow

Android gebruikt standaard Health Connect. De flow is:

1. Login met Laravel of gebruik de lokale incognito demo.
2. Open `Menu -> Health-sync`.
3. Actieve bron staat op `Health Connect`.
4. Tik `Handmatig synchroniseren`.
5. Geef read-only toestemming in Health Connect.
6. De app leest beschikbare data en stuurt die naar Laravel.

De native bridge gebruikt MethodChannel `summamove/health` met drie methods:

| Method | Doel |
|---|---|
| `isAvailable` | controleert of de bron beschikbaar is |
| `requestPermissions` | vraagt alleen read-permissions |
| `readChanges` | leest data tussen `from` en `to` en geeft genormaliseerde records/workouts terug |

Ondersteunde metrics:

- `steps`
- `heart_rate`
- `active_energy_burned`
- `dietary_energy_consumed`
- `water_intake`
- `workout_session`

## Offline demo

Op de loginpagina staat een incognito/privacy-icoon. Daarmee kan de app lokaal demo-data gebruiken zonder Laravel. Dit is bedoeld voor presentaties als de server of Wi-Fi niet meewerkt.

## Checks

```powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1
```

HealthKit staat in het technische plan, maar is geen vereiste voor de Android-demo.
