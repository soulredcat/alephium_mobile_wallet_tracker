# Goal: Alephium Wallet Monitor (Flutter)

## Goal
- Build a fully working Alephium monitor in Flutter (read-only) for Android/iOS.
- Provide a default address and support multi-address switching in one app.
- Support monitoring balance, locked balance, transaction history, and per-address balance-over-time chart.

## Default
- Default address: `1HkqAaFZYDh2r9K67JoSiwf4ph7f2qZU1trBDu9nC2C3U`

## Core features
- Add / delete / rename Alephium addresses.
- Fast address switching.
- Multi-address switching with per-address state/cache persistence.
- Manual refresh (pull-to-refresh) and auto-refresh every 60 seconds.
- Local cache via `SharedPreferences` (shows latest local data when offline).
- Sync status states:
  - online = complete data,
  - warning = balance updated, transaction list partial,
  - offline = sync failed.
- Transaction details with copy actions for hash, block hash, and timestamp.
- Dashboard total balance across all addresses.
- History filters for direction and status.
- Human-readable number formatting with thousand separators.

## API
- Base URL: `https://backend.mainnet.alephium.org`
- Summary: `GET /addresses/:address`
- Transactions: `GET /addresses/:address/transactions?page=1&limit=30`

## Installation
### Development
1. `cd flutter_app`
2. `flutter pub get`
3. `flutter run` (device/emulator)

### Android release
1. `cd flutter_app`
2. `flutter build apk --release`
3. Install `build/app/outputs/flutter-apk/app-release.apk` on device.

## Verification
- `dart analyze` ✅
- `dart test` ✅
- `flutter build apk --release` ✅
- Unit test coverage:
  - address format and validation parsing,
  - incoming/outgoing/fee transaction parsing,
  - timestamp parser (seconds/ms/microseconds/ISO).

## Production design notes
- Read-only only: does not store private keys.
- Cache-first strategy: latest data saved locally via `SharedPreferences` remains visible offline.
- Sync states: `Online`, `Warning`, `Offline`.
- Default address: `1HkqAaFZYDh2r9K67JoSiwf4ph7f2qZU1trBDu9nC2C3U`.
- BigInt-safe balance formatting with grouped separators to avoid precision issues.
