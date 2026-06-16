# SummaMove

SummaMove is een Laravel API met een Flutter-app voor sportchallenges. De app leest health-data op het toestel, zet die om naar een vast formaat en stuurt dit naar Laravel. Laravel regelt login, gebruikersdata, challenges, punten, shop, vrienden, teams, rankings en adminfuncties.

Laravel leest nooit zelf Health Connect, HealthKit of Samsung Health uit. Dat doet alleen de Flutter-app, na toestemming van de gebruiker.

## Projectstructuur

```text
app/                 Laravel API-code
database/            migrations, factories en seeders
docs/                API-contract en syncfixtures
mobile/              Flutter-app
routes/api.php       /api/v1 routes
tests/Feature/Api/   API-tests
release-apks/        demo-APK's die bewust via Git worden meegeleverd
```

`SPEC.md` en `FORMAT.md` blijven in de repo als werkdocumenten voor Coding Stack/Cavekit.

## Backend starten

Gebruik XAMPP voor MySQL. Start daarna Laravel apart op poort `8001`.

```powershell
cd C:\Users\zakel\Laravel\SummaMove
composer install
Copy-Item .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8001
```

Voor de demo moet XAMPP MySQL aan blijven en moet Laravel blijven draaien.

## Demo accounts

Alle seedaccounts gebruiken standaard wachtwoord `password123`, tenzij `DEMO_PASSWORD` in `.env` anders staat.

| Rol | E-mail |
|---|---|
| Gebruiker | `demo@example.com` |
| Admin | `admin@summamove.test` |

## APK's

De laatste demo-APK's staan in `release-apks/`. Deze map staat bewust in Git, zodat teamgenoten de APK's direct met `git pull` meekrijgen.

| APK | Bedoeld voor | API-url |
|---|---|---|
| `SummaMove-android-real-device.apk` | echte Android telefoon op dezelfde Wi-Fi | `http://192.168.178.109:8001/api/v1` |
| `SummaMove-android-emulator.apk` | Android Emulator op dezelfde pc | `http://10.0.2.2:8001/api/v1` |

GitHub kan een waarschuwing tonen omdat de APK's iets groter zijn dan 50MB per bestand. Voor deze demo is dat acceptabel; de bestanden blijven onder de harde GitHub-limiet van 100MB.

## Health Connect en offline demo

Op Android gebruikt de app standaard Health Connect. De gebruiker geeft read-only toestemming voor stappen, hartslag, actieve calorieen, voeding, water en workouts. De app schrijft niets terug naar Health Connect.

Als de server niet bereikbaar is, kan de loginpagina ook een lokale incognito demo starten. Die gebruikt in-memory demodata en heeft geen Laravel-server nodig.

## Belangrijkste API

Alle routes staan onder `/api/v1` en gebruiken JSON. Beveiligde routes gebruiken Sanctum bearer tokens.

Zie [docs/api-contract.md](docs/api-contract.md) voor het contract en `docs/fixtures/` voor voorbeeldpayloads.

## Flutter

De mobiele app staat in [mobile/README.md](mobile/README.md). Daar staan ook de buildcommands voor de echte Android APK en emulator APK.

## Tests

```powershell
php artisan test

cd mobile
flutter analyze
flutter test
```

Geen productie-uitrol in deze versie: geen storepublicatie, geen medische functies, geen AI-advies, geen betalingen en geen realtime chat.
