# Native health bridge contract

Channel: `summamove/health`

Elke call bevat:

```json
{"source":"health_connect|healthkit|samsung_health"}
```

## Methods

### `isAvailable`

Retourneert `true|false`.

### `requestPermissions`

Extra argument:

```json
{"metrics":["steps","heart_rate","active_energy_burned","dietary_energy_consumed","water_intake","workout_session"]}
```

Retourneert `true` als alle benodigde read-permissions zijn toegekend. De bridge vraagt nooit write-permissions.

### `readChanges`

Extra argument:

```json
{"cursor":"optional-platform-cursor","from":"ISO-8601 UTC","to":"ISO-8601 UTC"}
```

Retourneert:

```json
{
  "cursor": "next-platform-cursor",
  "records": [],
  "workouts": []
}
```

`records` en `workouts` volgen exact `docs/api-contract.md`. Native code normaliseert identifiers, units en timestamps voordat Dart ze ontvangt.

## Platformregels

- Android kiest standaard Health Connect. Samsung Health is een expliciet alternatief; nooit beide tegelijk actief.
- iOS gebruikt HealthKit read-only.
- Ontbrekende waarden niet als `0` verzinnen.
- Workout-calorieën blijven uitsluitend op workoutobjecten.
- Iedere bron moet echte-toesteltests krijgen voordat de adapter als gereed geldt.
