# Bruno USDT Miner

Un'app Flutter elegante e moderna per il mining di USDT con design crypto professionale, animazioni fluide e autenticazione Google Firebase.

## Caratteristiche

- 🎨 **UI/UX Moderna**: Design crypto professionale con tema scuro e animazioni fluide
- 🔐 **Autenticazione Google**: Login con Firebase Auth
- ⛏️ **Mining Automatico**: Mining continuo 24/7 anche quando l'app è chiusa
- 🚀 **Sistema Boost**: Guarda ads per raddoppiare la velocità di mining
- 🎁 **Reward Giornaliere**: 2 card reward con limite di 10 click ciascuna
- 💰 **Wallet**: Gestione balance mining e referral con possibilità di prelievo
- 📊 **Leaderboard**: Classifica top 10 utenti con top 3 evidenziati
- 🔗 **Referral System**: Condividi l'app e guadagna 0.02 USDT per condivisione

## Configurazione Firebase

### 1. Crea un progetto Firebase

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuovo progetto
3. Aggiungi un'app Android e/o iOS

### 2. Configura Android

1. Scarica il file `google-services.json`
2. Inseriscilo in `android/app/`
3. Aggiungi il plugin nel `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```
4. Aggiungi nel `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. Configura iOS

1. Scarica il file `GoogleService-Info.plist`
2. Aggiungilo al progetto Xcode
3. Configura l'autenticazione OAuth nella console Firebase

### 4. Abilita Google Sign-In

1. Vai su Authentication > Sign-in method
2. Abilita "Google" come provider di accesso
3. Aggiungi SHA-1 fingerprint per Android (opzionale ma raccomandato)

## Installazione

```bash
flutter pub get
flutter run
```

## Note Importanti

- Il mining è configurato per essere molto lento (0.00001 USDT/secondo)
- Il prelievo richiede un minimo di 100 USDT
- I reward giornalieri hanno un limite di 10 click ciascuno
- Il boost mining dura 1 ora e richiede 2 ads
- Le reward aprono Chrome custom tabs

## Struttura Progetto

```
lib/
├── main.dart                 # Entry point
├── theme/
│   └── app_theme.dart       # Tema crypto
├── services/
│   ├── auth_service.dart    # Servizio autenticazione
│   ├── mining_service.dart  # Logica mining
│   └── storage_service.dart # Storage locale
├── screens/
│   ├── intro_screen.dart    # Schermata introduttiva
│   ├── login_screen.dart    # Login Google
│   ├── main_tabs.dart       # Navigation principale
│   ├── home_screen.dart     # Home con mining card
│   ├── boost_screen.dart    # Boost mining
│   ├── wallet_screen.dart   # Wallet (mining + referral)
│   ├── withdraw_screen.dart # Prelievo USDT
│   ├── settings_screen.dart # Impostazioni
│   └── leaderboard_screen.dart # Classifica
└── widgets/
    ├── mining_card.dart     # Card mining
    └── reward_card.dart     # Card reward giornaliere
```

## Licenza

Questo progetto è solo a scopo educativo.
