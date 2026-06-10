# SummaMove mobile

Flutter-source voor de read-only health-syncdemo.

## Flow

1. Login bij Laravel en bewaar Sanctum-token in `flutter_secure_storage`.
2. Kies precies één actieve bron voor het toestel.
3. Vraag expliciet read-permissions.
4. Lees wijzigingen via een `HealthSourceAdapter`.
5. Normaliseer naar het Laravel-contract en synchroniseer handmatig.
6. Toon syncresultaat en dagoverzicht.

De mock-adapter werkt zonder native SDK. Health Connect, HealthKit en Samsung Health gebruiken hetzelfde MethodChannel-contract in `docs/native-bridge-contract.md`.

## Lokaal opzetten

Omdat platformboilerplate niet zonder Flutter SDK is gegenereerd:

```powershell
flutter create --platforms=android,ios .
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Sluit daarna de native MethodChannel-hostbridges aan volgens het contract. HealthKit vereist Mac/Xcode; Samsung Health vereist de vendor SDK en developer mode.
