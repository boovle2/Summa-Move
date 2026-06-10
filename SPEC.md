# SPEC

## §G GOAL
Laravel 13 API + Flutter client synchroniseren read-only health-data idempotent per toestel/bron.

## §C CONSTRAINTS
- Werk uitsluitend branch `laravel-api`; push uitsluitend `origin/laravel-api`.
- Laravel root; Flutter source in `mobile/`.
- Productie DB MySQL; tests SQLite.
- Laravel leest health-platformen nooit direct.
- Eerste demo: geen achtergrond-sync, write-back, medische functies, AI-advies of appstore-publicatie.
- HealthKit/echt toestel vereist Mac/Xcode; Samsung vereist vendor SDK/developer mode.

## §I INTERFACES
- api: `POST /api/v1/auth/register|login`; `DELETE /api/v1/auth/logout`
- api: `PUT /api/v1/devices/{client_device_id}`
- api: `POST /api/v1/health/sync`
- api: `GET /api/v1/health/status?device_id=...`
- api: `GET /api/v1/health/daily-summary?date=YYYY-MM-DD&timezone=Europe/Amsterdam`
- dart: `HealthSourceAdapter.isAvailable|requestPermissions|readChanges`
- docs: `docs/api-contract.md`; `docs/fixtures/*.json`

## §V INVARIANTS
V1: `user_id` uitsluitend Sanctum-token; gebruiker ziet/wijzigt alleen eigen data.
V2: ∀ toestel → maximaal 1 actieve source.
V3: sync batch `records + workouts <= 500`.
V4: sync write ! transactie; cursor alleen na volledig succesvolle verwerking.
V5: unieke scalar sleutel = `user_id + source + metric_type + external_id`.
V6: herhaalde `sync_id`/records → geen duplicaten.
V7: tijden UTC opslaan; oorspronkelijke timezone bewaren.
V8: ontbrekende metrics blijven `null`; workout-calorieën ≠ actieve calorieëntotaal.
V9: payloads ⊥ logs; foutmelding bevat geen health-payload.
V10: Flutter adapters → identiek genormaliseerd contract; read-only.

## §T TASKS
id|status|task|cites
T1|x|Laravel scaffold + Sanctum|V1,I.api
T2|x|datamodel + auth/device API|V1,V2,V5,I.api
T3|x|health sync/status/summary + tests|V3,V4,V6,V7,V8,V9,I.api
T4|x|Flutter adaptercontract + mockflow + UI|V10,I.dart
T5|x|API-contract, fixtures, README, Laravel eindverificatie|V1,V3,V4,V5,V6,V7,V8,V9,V10,I.docs
T6|.|native Health Connect/HealthKit/Samsung bridges + echte-toesteltests|V10,I.dart

## §B BUGS
id|date|cause|fix
B1|2026-06-10|Sanctum abilities aliases ontbraken|aliases geregistreerd in `bootstrap/app.php`
B2|2026-06-10|offset timestamps direct doorgegeven → lokale kloktijd opgeslagen|V7
