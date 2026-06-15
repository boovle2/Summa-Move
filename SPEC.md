# SPEC

## §G GOAL
SummaMove Laravel 13 API + Flutter app leveren health-gestuurde gamification, social, shop, ranking, profiel & Flutter-admin volgens Figma-prototype.

## §C CONSTRAINTS
- Werk uitsluitend branch `laravel-api`; Laravel root; Flutter `mobile/`.
- Productie DB MySQL; tests SQLite.
- Laravel leest health-platformen nooit direct; Flutter adapters read-only.
- Normale gebruiker ⊥ handmatige health/challengevoortgang.
- Admin-demodata beïnvloedt profiel/challenges/punten; ⊥ leaderboards.
- Eerste versie Nederlands; geen push, realtime sockets, betalingen, medische functies, AI-advies of storepublicatie.
- Bestaande `/api/v1/auth`, `/devices`, `/health` compatibel houden.

## §I INTERFACES
- api.auth: `POST /api/v1/auth/register|login`; `DELETE /api/v1/auth/logout`
- api.health: `PUT /api/v1/devices/{client_device_id}`; `POST /api/v1/health/sync`; `GET /api/v1/health/status|daily-summary`
- api.me: `GET /api/v1/me/home|profile|settings`; `PUT /api/v1/me/settings`
- api.challenge: `GET /api/v1/challenges|challenge-assignments`; `GET|POST /api/v1/challenges/{challenge}[|/start]`
- api.social: `/api/v1/friends|friend-requests|messages|teams`
- api.shop: `GET /api/v1/shop/items`; `POST /api/v1/shop/items/{item}/purchase`; `PUT /api/v1/characters/{item}/equip`
- api.rank: `GET /api/v1/rankings?period=today|week|progress|friends`
- api.admin: `/api/v1/admin/dashboard|challenges|shop-items|teams|users|assignments|point-adjustments|demo-health|audits`
- dart: `HealthSourceAdapter.isAvailable|requestPermissions|readChanges`
- docs: `docs/api-contract.md`; `docs/fixtures/*.json`

## §V INVARIANTS
V1: `user_id` uitsluitend Sanctum-token; gebruiker ziet/wijzigt alleen eigen data.
V2: ∀ toestel → maximaal 1 actieve health source.
V3: sync batch `records + workouts <= 500`.
V4: sync write ! transactie; cursor alleen na volledig succesvolle verwerking.
V5: unieke scalar sleutel = `user_id + source + metric_type + external_id`.
V6: herhaalde `sync_id`/records/challengebeloning → geen duplicaten.
V7: tijden UTC opslaan; oorspronkelijke timezone bewaren.
V8: ontbrekende metrics blijven `null`; workout-calorieën ≠ actieve calorieëntotaal.
V9: payloads ⊥ logs; foutmelding bevat geen health-payload.
V10: Flutter adapters → identiek genormaliseerd contract; read-only.
V11: normale gebruiker ⊥ directe progress/point/health write.
V12: challenge complete → punten exact 1x via idempotent `point_transactions`.
V13: shop purchase ! atomair; saldo nooit `< 0`.
V14: `admin` middleware ! vóór iedere `/api/v1/admin/*` handler.
V15: `admin_demo` data/transactions ⊥ rankingberekening.
V16: social reads/writes uitsluitend geaccepteerde relatie of eigen verzoek/team.
V17: Flutter route/admin UI zichtbaar iff sessierol `admin`.
V18: alle hoofdflows tonen loading/error/empty/success status.

## §T TASKS
id|status|task|cites
T1|x|Laravel scaffold + Sanctum|V1,I.api.auth
T2|x|health datamodel + auth/device API|V1,V2,V5,I.api.health
T3|x|health sync/status/summary + tests|V3,V4,V6,V7,V8,V9,I.api.health
T4|x|Flutter adaptercontract + mockflow|V10,I.dart
T5|x|API-contract, fixtures, README|V1,V3,V4,V5,V6,V7,V8,V9,V10,I.docs
T6|.|native Health Connect/HealthKit/Samsung bridges + echte-toesteltests|V10,I.dart
T7|x|gamification/social/shop/ranking/admin datamodel + API|V1,V6,V11,V12,V13,V14,V15,V16,I.api.me,I.api.challenge,I.api.social,I.api.shop,I.api.rank,I.api.admin
T8|x|uitgebreide prototype-seed + backend producttests|V6,V12,V13,V14,V15,V16
T9|x|Flutter Riverpod + go_router + repositories|V17,V18
T10|x|user flows: home/challenges/social/shop/ranking/profile/settings|V11,V16,V18,I.api.me,I.api.challenge,I.api.social,I.api.shop,I.api.rank
T11|x|Flutter admin dashboard/content/toekenning/demodata/audit|V14,V15,V17,V18,I.api.admin
T12|x|eindvalidatie: Laravel, Flutter, APK, emulator, security, review|V1,V6,V11,V12,V13,V14,V15,V16,V17,V18

## §B BUGS
id|date|cause|fix
B1|2026-06-10|Sanctum abilities aliases ontbraken|aliases geregistreerd in `bootstrap/app.php`
B2|2026-06-10|offset timestamps direct doorgegeven → lokale kloktijd opgeslagen|V7
B3|2026-06-15|testfixture gebruikte geen UUID voor `sync_id`|V6
B4|2026-06-15|ranking en teamdetail serialiseerden te brede user-data|V1,V16
B5|2026-06-15|demo-health kon bij latere normale recalculatie als echte beloning tellen|V15
B6|2026-06-15|thema werd opgeslagen maar niet direct in Flutter toegepast|V18
