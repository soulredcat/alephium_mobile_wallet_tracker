# Alephium Wallet Monitor (Flutter)

Alephium read-only wallet monitor based on Flutter:
- Read-only wallet monitor (does not store private keys)
- Multi-address support with fast switching
- Balance, transactions, and per-address balance history chart
- Local cache via `SharedPreferences`

## Core features

- Monitor balance and locked balance per address
- Transaction history + transaction details (time, fee, status) with copy actions for hash/block/timestamp
- Transaction history filters (All / Incoming / Outgoing) for quick analysis
- Auto refresh + manual refresh
- Local cache for offline mode (latest data remains visible)
- Data status UI (red = sync failed, yellow = partial data)
- Dashboard layout includes:
  - sync status banner,
  - section headers + quick actions,
  - active address summary + combined summary cards,
  - transaction row showing direction, time, and compact hash
- Transaction filters (All / Incoming / Outgoing and Success / Failed)
- Balance formatting with thousand separators for readability

## Quick start

1. Install Flutter SDK + Android Studio/ADB and ensure a device is detected.
2. Enter the Flutter project folder:

```bash
cd flutter_app
```

3. Install dependencies:

```bash
flutter pub get
```

4. Run on phone (dev mode):

```bash
flutter run
```

5. Build a release APK for manual installation:

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

If build fails in Windows due to Kotlin cache issues, clean and rebuild:

```bash
flutter clean
flutter pub get
```

Then build release again:

```bash
flutter build apk --release
```

In this project, release APK generation has been validated.

### Connectivity & sync

- The app uses `connectivity_plus` to detect online/offline state.
- When offline:
  - API refresh is automatically disabled (cached data stays visible),
  - status banner shows offline mode,
  - refresh action shows Wi-Fi-off icon.

## Architecture

- `lib/models`: data models / DTOs
- `lib/services`: state orchestration and business logic
- `lib/repository`: API and local cache access
- `lib/widgets`: reusable UI components
- `lib/utils`: formatters and constants

## Default address
- `1HkqAaFZYDh2r9K67JoSiwf4ph7f2qZU1trBDu9nC2C3U`

## Runtime notes
- API backend: `https://backend.mainnet.alephium.org`
- Default refresh interval: 60 seconds
- The app stores the latest transactions/cache so recent data is still visible when offline.
