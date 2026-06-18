# SPEC.md FORMAT

Single file in project root. Cavekit commands read this before touching `SPEC.md`.

## SECTIONS

Fixed order:

```text
# SPEC

## §G GOAL
one line: what code must do

## §C CONSTRAINTS
- non-negotiable boundary
- locked tech, path, branch, or scope

## §I INTERFACES
- external surface: API, command, file, env, route, screen contract

## §V INVARIANTS
V1: numbered, testable rule that must hold

## §T TASKS
id|status|task|cites
T1|.|todo task|V1,I.api
T2|~|work in progress|V1
T3|x|done task|-

## §B BUGS
id|date|cause|fix
B1|2026-06-16|bug cause|V1
```

## TABLE RULES

- Status: `.` todo, `~` wip, `x` done.
- IDs monotonic: never reuse `V`, `T`, or `B` numbers.
- Escape literal pipe as `\|`.
- Empty cell becomes `-`.
- `cites` references related invariants/interfaces, for example `V6,I.api.health`.

## CAVEMAN STYLE

- Compact fragments are preferred.
- Preserve code, paths, identifiers, URLs, exact errors, numbers, SQL, regex.
- Avoid filler words.
- Use symbols only when they make the rule clearer.

Common symbols:

```text
->  leads to / becomes / triggers
!   must
?   optional
⊥   forbidden / never
!=  not equal
<=  at most
>=  at least
&   and
|   or
```

## WRITE RULES

- `spec` may create or amend sections.
- `build` may only flip §T status and edit implementation files.
- `check` is read-only.
- Failed verification should produce a §B row when the cause is a missing or wrong invariant.
