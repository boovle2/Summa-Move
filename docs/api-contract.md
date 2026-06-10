# SummaMove API-contract

Basis-URL: `/api/v1`

Formaat: JSON

Authenticatie: `Authorization: Bearer <sanctum-token>`

## Invariants

- `user_id` komt uitsluitend uit het Sanctum-token.
- Per toestel is precies één health-bron actief.
- Alle datums/tijden worden als ISO-8601 met offset aangeleverd en als UTC opgeslagen.
- `records` en `workouts` bevatten samen maximaal 500 items.
- Een `sync_id` is idempotent. De unieke recordsleutel is `user_id + source + metric_type + external_id`.
- Cursor wordt uitsluitend bijgewerkt na een volledig succesvolle transactie.
- Ontbrekende waarden blijven `null`; workout-calorieën tellen niet mee als algemene actieve calorieën.
- De server logt geen volledige health-payloads.

## Metrics

| type | eenheid |
|---|---|
| `steps` | `count` |
| `heart_rate` | `bpm` |
| `active_energy_burned` | `kcal` |
| `dietary_energy_consumed` | `kcal` |
| `water_intake` | `ml` |
| `workout_session` | `seconds` |

Bronnen: `health_connect`, `healthkit`, `samsung_health`.

Platformcombinaties:

- `ios` gebruikt `healthkit`.
- `android` gebruikt `health_connect` of `samsung_health`.
- De syncbron moet gelijk zijn aan de actieve bron en iedere aangeleverde metric moet read-permission hebben.

## Authenticatie

### `POST /auth/register`

```json
{"name":"Demo User","email":"demo@example.com","password":"password123","password_confirmation":"password123","device_name":"flutter-demo"}
```

### `POST /auth/login`

```json
{"email":"demo@example.com","password":"password123","device_name":"flutter-demo"}
```

Register/login retourneren `data.user` en `data.token`. Logout gebruikt `DELETE /auth/logout`.

## Toestel registreren

### `PUT /devices/{client_device_id}`

```json
{
  "platform": "android",
  "active_source": "health_connect",
  "app_version": "0.1.0",
  "granted_metrics": ["steps", "heart_rate", "active_energy_burned", "workout_session"]
}
```

`platform`: `android|ios`. De actieve bron moet passen bij de mobiele adapter.

## Health synchroniseren

### `POST /health/sync`

```json
{
  "sync_id": "68b344e7-8cb8-45ec-a18c-1863a29387e1",
  "device_id": "demo-device",
  "source": "health_connect",
  "cursor": "next-platform-cursor",
  "records": [
    {
      "external_id": "steps-2026-06-10",
      "metric_type": "steps",
      "value": 8450,
      "unit": "count",
      "measured_from": "2026-06-09T22:00:00Z",
      "measured_to": "2026-06-10T21:59:59Z",
      "timezone": "Europe/Amsterdam"
    }
  ],
  "workouts": []
}
```

Succesresponse:

```json
{
  "data": {
    "sync_id": "68b344e7-8cb8-45ec-a18c-1863a29387e1",
    "status": "completed",
    "stored": 1,
    "duplicates": 0,
    "rejected": 0,
    "next_cursor": "next-platform-cursor"
  }
}
```

Volledige voorbeelden staan in `docs/fixtures/`.

## Status en dagoverzicht

```text
GET /health/status?device_id=demo-device
GET /health/daily-summary?date=2026-06-10&timezone=Europe/Amsterdam
```

Het dagoverzicht bevat totalen of `null`, plus `latest`, `average`, `minimum` en `maximum` voor hartslag.
