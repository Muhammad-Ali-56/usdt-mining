# Setup Sottoscrizioni In-App Reali

Questo documento spiega come configurare le sottoscrizioni in-app reali per l'app Bruno USDT Miner.

## Product IDs Configurati

I seguenti Product IDs sono configurati nel codice:

- `starter_monthly_subscription` - Starter Plan (sottoscrizione mensile)
- `pro_monthly_subscription` - Pro Plan (sottoscrizione mensile)
- `elite_monthly_subscription` - Elite Plan (sottoscrizione mensile)

## Configurazione Android (Google Play Console)

1. Vai su [Google Play Console](https://play.google.com/console)
2. Seleziona la tua app
3. Vai su **Monetizzazione** > **Prodotti e sottoscrizioni** > **Sottoscrizioni**
4. Crea 3 sottoscrizioni con i seguenti ID prodotto:
   - `starter_monthly_subscription`
   - `pro_monthly_subscription`
   - `elite_monthly_subscription`
5. Configura per ognuna:
   - Nome del prodotto
   - Prezzo mensile
   - Periodo di rinnovo (1 mese)
   - Impostazioni di rinnovo automatico
   - Periodo di prova gratuita (opzionale)
   - Prezzo introduttivo (opzionale)

6. **IMPORTANTE**: Configura come "Sottoscrizioni" (non prodotti consumabili o non consumabili)

## Configurazione iOS (App Store Connect)

1. Vai su [App Store Connect](https://appstoreconnect.apple.com)
2. Seleziona la tua app
3. Vai su **Monetizzazione** > **Sottoscrizioni**
4. Crea un gruppo di sottoscrizioni (es. "Premium Plans")
5. Crea 3 sottoscrizioni con i seguenti ID prodotto:
   - `starter_monthly_subscription`
   - `pro_monthly_subscription`
   - `elite_monthly_subscription`
6. Configura per ognuna:
   - Nome del prodotto
   - Prezzo mensile
   - Durata della sottoscrizione (1 mese)
   - Periodo di prova gratuita (opzionale)
   - Prezzo introduttivo (opzionale)

## Modificare Product IDs (Se Necessario)

Se vuoi usare Product IDs diversi, modifica il file `lib/services/subscription_service.dart`:

```dart
static const Map<SubscriptionTier, String> _productIds = {
  SubscriptionTier.starter: 'il_tuo_product_id_starter',
  SubscriptionTier.pro: 'il_tuo_product_id_pro',
  SubscriptionTier.elite: 'il_tuo_product_id_elite',
};
```

## Testing

### Android (Test Track)

1. Usa account di test configurati in Google Play Console
2. L'app deve essere pubblicata almeno in Test Track interno
3. Gli acquisti di test non verranno addebitati

### iOS (Sandbox)

1. Crea account di test in App Store Connect (Users and Access > Sandbox Testers)
2. Effettua logout dall'App Store sullo smartphone
3. Quando acquisti, accedi con l'account sandbox
4. Gli acquisti di sandbox non verranno addebitati

## Funzionalità Implementate

✅ Acquisto sottoscrizioni reali  
✅ Gestione sottoscrizioni ricorrenti  
✅ Restore acquisti precedenti  
✅ Verifica stato sottoscrizione  
✅ UI con prezzi reali  
✅ Gestione errori di acquisto  

## Note Importanti

- Le sottoscrizioni devono essere configurate PRIMA di pubblicare l'app
- I Product IDs devono essere IDENTICI su Android e iOS
- Le sottoscrizioni sono mensili e si rinnovano automaticamente
- Gli utenti possono cancellare le sottoscrizioni dalle impostazioni del dispositivo
- Implementa verifica server-side per produzione (opzionale ma consigliato)

## Prossimi Passi (Opzionali)

Per maggiore sicurezza in produzione:

1. Implementa verifica server-side dei receipt
2. Usa RevenueCat o un servizio simile per gestione centralizzata
3. Aggiungi analytics per tracking acquisti
4. Implementa gestione delle sottoscrizioni che scadono






