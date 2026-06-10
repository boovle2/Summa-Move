# SummaMove

SummaMove is een Laravel 13 API met een Flutter-client voor read-only synchronisatie van health-data. De mobiele app leest data uit Health Connect, HealthKit of Samsung Health, normaliseert die en stuurt deze naar Laravel. Laravel leest nooit rechtstreeks uit een health-platform.

## Projectstructuur

```text
app/                 Laravel API
database/            migrations, factories en seeders
docs/                API-contract en vaste syncfixtures
mobile/              Flutter-source en platformadaptercontracten
routes/api.php       publieke /api/v1-routes
tests/Feature/Api/   API-featuretests
```

## Backend starten

Vereisten: PHP 8.3+, Composer en MySQL.

```powershell
Copy-Item .env.example .env
composer install
php artisan key:generate
php artisan migrate
php artisan serve --host=0.0.0.0 --port=8001
```

Voor tests wordt SQLite in-memory gebruikt:

```powershell
php artisan test
```

## API

Alle beveiligde routes gebruiken Sanctum bearer tokens met abilities:

- `device:write`
- `health:sync`
- `health:read`

Zie [docs/api-contract.md](docs/api-contract.md) voor requests, responses en invariants.

## Flutter

De Flutter-broncode staat in `mobile/`. De mock-adapter maakt lokale end-to-end ontwikkeling mogelijk zonder health-platform. Health Connect, HealthKit en Samsung Health gebruiken hetzelfde MethodChannel-contract.

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

De native hostbridges moeten op SDK-geschikte machines worden aangesloten en getest:

- Health Connect: Android SDK + echt/emulated ondersteund Android-toestel.
- HealthKit: Mac, Xcode en echte iPhone.
- Samsung Health: Android 10+, Samsung Health Data SDK en developer mode.

## Grenzen eerste demo

Geen achtergrond-sync, write-back, medische functies, AI-advies of appstore-publicatie. Ontbrekende metrics blijven `null`; workout-calorieën worden niet bij algemene actieve calorieën opgeteld.
