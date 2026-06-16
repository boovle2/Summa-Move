# Verbeterplan SummaMove

## Samenvatting

Dit verbeterplan is bedoeld voor de teamvergadering. Het beschrijft welke onderdelen van de SummaMove repo opgeschoond kunnen worden zonder de demo te breken.

De huidige versie werkt: Laravel-tests, Flutter analyze en Flutter-tests zijn groen. De verbeteringen hieronder gaan vooral over netheid, onderhoudbaarheid en duidelijke documentatie.

## Prioriteit 1: Direct opruimen

### Laravel welcome page vervangen

**Probleem:** `resources/views/welcome.blade.php` is nog de grote standaard Laravel welcome page.

**Waarom verbeteren:** het project is een API met een Flutter app. De standaardpagina voegt weinig toe en maakte eerder CSS-waarschuwingen zichtbaar.

**Aanpak:** vervangen door een simpele API-statuspagina of JSON-response, bijvoorbeeld: `SummaMove API draait`.

### Android TODO-comments opruimen

**Probleem:** `mobile/android/app/build.gradle.kts` bevat nog standaard Flutter TODO-comments.

**Waarom verbeteren:** het lijkt alsof belangrijke Android-config nog niet gedaan is, terwijl `applicationId` al bestaat.

**Aanpak:** TODO's verwijderen of vervangen door een duidelijke demo-opmerking over debug signing.

## Prioriteit 2: Onderhoudbaarheid

### Grote Flutter screen-file splitsen

**Probleem:** `mobile/lib/src/screens/product_pages.dart` is ongeveer 1484 regels.

**Waarom verbeteren:** teamleden kunnen frontend-schermen makkelijker aanpassen als niet alles in een mega-bestand staat.

**Aanpak:** later splitsen naar feature-bestanden:

- `challenges_pages.dart`
- `social_pages.dart`
- `shop_pages.dart`
- `ranking_pages.dart`
- `profile_settings_pages.dart`
- `admin_pages.dart`

### Offline demo data apart zetten

**Probleem:** `mobile/lib/src/services/offline_demo_repository.dart` bevat demo-data en repository-logica samen.

**Waarom verbeteren:** demo-data aanpassen wordt makkelijker en de repository blijft leesbaar.

**Aanpak:** demo-data verplaatsen naar een aparte file, bijvoorbeeld `offline_demo_data.dart`.

### Composer metadata aanpassen

**Probleem:** `composer.json` noemt het project nog een Laravel skeleton.

**Waarom verbeteren:** GitHub en projectoverzicht ogen netter en professioneler.

**Aanpak:** naam en beschrijving aanpassen naar SummaMove.

## Prioriteit 3: Documentatie en workflow

### SPEC.md actualiseren

**Probleem:** Health Connect is gebouwd, maar `SPEC.md` noemt sommige platform-bridge taken nog als een open gecombineerde taak.

**Waarom verbeteren:** de SPEC moet kloppen met de huidige staat van het project.

**Aanpak:** Health Connect markeren als gedaan. HealthKit en Samsung Health als vervolgplan laten staan.

### .env.example aanvullen

**Probleem:** README noemt `DEMO_PASSWORD`, maar `.env.example` bevat die variabele nog niet.

**Waarom verbeteren:** nieuwe teamleden kunnen sneller dezelfde demo-setup draaien.

**Aanpak:** `DEMO_PASSWORD=password123` toevoegen aan `.env.example`.

### GitHub Actions overwegen

**Probleem:** er is nog geen `.github/workflows` map.

**Waarom verbeteren:** tests worden nu lokaal gedraaid. CI zou automatisch checken of pull requests veilig zijn.

**Aanpak:** later een simpele workflow toevoegen voor:

- `composer install`
- `php artisan test`
- `flutter analyze`
- `flutter test`

## Bewust niet opruimen

### release-apks/

De APK's blijven in Git, omdat teamgenoten ze dan direct met `git pull` krijgen. Nadeel is dat de repo groter wordt en GitHub waarschuwt boven 50MB per bestand. Voor deze demo is dat acceptabel.

### mobile/ios/

Niet verwijderen. iOS en HealthKit blijven onderdeel van het technische vervolgplan, ook al is Android de demo-focus.

### SPEC.md en FORMAT.md

Niet verwijderen. Deze horen bij de Coding Stack en Cavekit workflow.

### Lokale cache en build-output

Mappen zoals `.env`, `vendor`, `.dart_tool`, `.gradle`, `.idea`, `.vscode`, logs en SQLite testbestanden blijven genegeerd. Ze hoeven niet in Git.

## Testplan na cleanup

Na elke cleanup-ronde uitvoeren:

```powershell
php artisan test

cd mobile
flutter analyze
flutter test
```

Extra checks:

```powershell
git status --short
git ls-files release-apks
```

## Acceptatiecriteria

- Twee APK's blijven aanwezig onder `release-apks/`.
- Laravel API blijft werken.
- Flutter app blijft werken.
- Demo-login, offline demo en Health Connect flow blijven werken.
- Tests blijven groen.
- Repo is duidelijker voor teamgenoten en beoordelaar.
