# Challenge- en Unlockplan SummaMove

## Doel voor de demo

Dit document is bedoeld voor het overleg van morgen. Het beschrijft hoe we SummaMove realistischer en meer app-ready kunnen maken met challenges die passen bij MBO-studenten.

De app moet niet voelen alsof de challenges alleen in de designfase zijn bedacht. De challenges moeten logisch passen bij een normale schooldag: pauze, fietsen naar school, trap nemen, praktijkles, gym/sport, water drinken en korte beweegmomenten.

Belangrijk uitgangspunt: normale gebruikers vullen voortgang niet zelf in. Voortgang komt uit Health Connect of uit passende workouts die door de app worden gesynchroniseerd.

## Waarom de oude challenges aangepast worden

De huidige challenge-lijst bevat nog targets die minder goed passen bij echte health-data, zoals `50 squats`, `300 springtouw` of algemene stappen/minuten zonder duidelijke context.

Dat is niet ideaal voor de demo, omdat:

- Health Connect niet betrouwbaar losse herhalingen zoals squats of springtouwtellingen levert.
- Algemene challenges minder herkenbaar zijn voor MBO-studenten.
- De app sterker wordt als elke challenge meetbaar en uitlegbaar is.
- De demo beter werkt als je kunt laten zien: gebruiker start challenge, synchroniseert health-data, challenge wordt afgerond, punten komen erbij.

Daarom verschuiven we naar haalbare MBO-challenges die gebaseerd zijn op stappen, water, actieve calorieen, workoutduur en activiteitstype.

## Nieuwe MBO challenge-set

| Slug | Titel | Doel | Metric | Target | Punten |
|---|---|---|---|---:|---:|
| `pauze-rondje` | Pauze rondje | Loop in of na de pauze een kort rondje | stappen | 1.500 | 35 |
| `tussen-de-lessen` | Tussen de lessen | Haal extra stappen tijdens je schooldag | stappen | 3.000 | 50 |
| `trap-inplaats-van-lift` | Trap in plaats van lift | Kies voor actieve beweging of traplopen | workoutduur | 8 min | 45 |
| `fiets-naar-school` | Fiets naar school | Registreer een fietsrit naar school | cycling workout | 15 min | 70 |
| `actieve-praktijkles` | Actieve praktijkles | Registreer beweging tijdens praktijk/gym | workoutduur | 20 min | 80 |
| `water-tijdens-lesdag` | Water tijdens lesdag | Drink genoeg water tijdens school | water | 750 ml | 30 |
| `na-school-beweging` | Na school beweging | Beweeg na school nog even actief | workoutduur | 25 min | 90 |
| `sportieve-schooldag` | Sportieve schooldag | Haal een hoge maar haalbare stappenscore | stappen | 7.500 | 100 |
| `hardloop-na-school` | Hardloop na school | Registreer een hardloopsessie | running workout | 20 min | 120 |
| `week-challenge` | Week challenge | Rond 3 schooldag-challenges af in een week | challenge-count | 3 | 150 |

## Quick challenges

Quick challenges moeten kort en makkelijk te begrijpen zijn. Ze zijn handig voor de demo en voor studenten die weinig tijd hebben.

| Slug | Titel | Doel | Metric | Target | Punten |
|---|---|---|---|---:|---:|
| `quick-pauze-walk` | Pauze walk | Wandel 5 minuten | walking/workoutduur | 5 min | 20 |
| `quick-stretch` | Stretch break | Rek en stretch 5 minuten | yoga/workoutduur | 5 min | 20 |
| `quick-trap` | Trap challenge | Neem 5 minuten actief de trap of beweeg actief | workoutduur | 5 min | 25 |
| `quick-water` | Water check | Voeg water toe via Health Connect | water | 250 ml | 10 |

## Emoji unlocks

Characters en shopitems mogen meer character-achtig worden. Daarvoor gebruiken we emoji in plaats van alleen Material icons.

Technisch voorstel:

- Shop/characters gebruiken `icon_key` met prefix `emoji:`.
- Voorbeeld: `emoji:🏃`.
- Flutter rendert `emoji:*` als tekst/emoji.
- Bestaande icon keys blijven werken voor challenges en achievements.

Voorstel voor unlocks:

| Unlock | Icon key | Betekenis |
|---|---|---|
| Runner | `emoji:🏃` | Voor studenten die wandel/hardloopchallenges doen |
| Fietser | `emoji:🚴` | Voor fiets-naar-school challenges |
| Gym | `emoji:💪` | Voor sport/praktijk/gym beweging |
| Zen | `emoji:🧘` | Voor stretch en rustige beweegmomenten |
| Waterheld | `emoji:💧` | Voor water-challenges |
| Teamspeler | `emoji:🤝` | Voor vrienden/team challenges |
| Kampioen | `emoji:🏆` | Voor hoge scores en leaderboard |
| Streak | `emoji:🔥` | Voor meerdere dagen actief blijven |

Challenges en achievements mogen gewone iconen houden, omdat die in lijsten vaak duidelijker en rustiger zijn.

## Demo-flow voor klant/beoordelaar

De demo moet snel kunnen laten zien dat de app echt werkt.

Voorstel demo-user:

| Challenge | Demo-progress | Waarom |
|---|---:|---|
| `pauze-rondje` | 1.250 / 1.500 stappen | Na sync snel afrondbaar |
| `water-tijdens-lesdag` | 500 / 750 ml | Laat water-metric zien |
| `fiets-naar-school` | 12 / 15 minuten | Laat workout/activity-type zien |

Demo-flow:

1. Login als demo-user.
2. Open health-sync.
3. Synchroniseer Health Connect-data.
4. Challenge wordt afgerond.
5. Punten stijgen.
6. Leaderboard/shop/avatar zichtbaar maken.

Als Health Connect of server niet werkt, blijft de offline incognito demo bestaan voor presentatie.

## Technische aanpassingen

Later uitvoeren in code:

- Laravel seeddata vervangen door de nieuwe MBO challenge-set.
- Offline demo repository dezelfde challenge- en unlockdata geven.
- Flutter visual helper uitbreiden:
  - `emoji:*` renderen als emoji-tekst.
  - bestaande keys blijven Material icons.
- Gamification verbeteren:
  - challenge-progress alleen berekenen met health-data vanaf `challenge_assignments.started_at`.
  - punten blijven idempotent: exact 1x per voltooide challenge.
- Leaderboards blijven gebaseerd op echte non-demo data.
- Admin-demo blijft bestaan, maar telt niet mee in echte leaderboards.

## Testplan

Backend:

```powershell
php artisan test
```

Flutter:

```powershell
cd mobile
flutter analyze
flutter test
```

Extra checks:

- Oude health-data van voor challenge-start telt niet mee.
- Punten worden exact 1x gegeven per afgeronde challenge.
- Emoji unlocks worden goed getoond in shop/avatar.
- Offline demo toont dezelfde MBO-challenges.
- Leaderboard ververst na nieuwe echte health-sync.
- Admin-demo data telt niet mee in echte leaderboards.

## Acceptatiecriteria

- Challenge-lijst gebruikt concrete MBO-schooldagtaal.
- Geen generieke designfase-termen of niet-meetbare reps als hoofdlogica.
- Challenges zijn uitlegbaar met Health Connect-data.
- Shop/characters voelen meer als unlocks door emoji.
- Demo-user heeft bijna-afgeronde challenges voor een snelle presentatie.
- Normale gebruikers kunnen progress niet handmatig verhogen.
- Offline demo blijft bruikbaar als fallback.
