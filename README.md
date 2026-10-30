# MONEYFLOW — Flutter Android

MONEYFLOW is a local-first personal finance tracker with manual transaction entry and an Android NotificationListenerService prototype.

## Features
- Dark fintech dashboard
- Income and expense entry
- Local SQLite transaction storage
- Monthly totals and category chart
- Android notification listener permission flow
- Heuristic parsing for common Indonesian transaction notification wording
- No m-banking credentials, PIN, or password collection

## Requirements
- Flutter stable (Dart 3.3+)
- Android Studio / Android SDK
- JDK 17
- Android device or emulator

## Run
From this folder:

```bash
flutter pub get
flutter run
```

To build an APK:

```bash
flutter build apk --release
```

APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## Enable automatic detection
1. Install and open MONEYFLOW.
2. Open Settings or tap **Aktifkan** on the dashboard.
3. Android opens **Notification access** settings.
4. Enable MONEYFLOW.
5. Allow bank/e-wallet apps to show transaction notifications.
6. Return to MONEYFLOW and pull down to refresh.

## Important limitations
- Android notification access is broad: the OS permission technically lets the listener observe notifications from other apps. The current app queues notification text locally and does not upload it.
- The parser is heuristic and is not bank-certified. Bank/e-wallet notification formats vary; some notifications omit amounts, and some wording may be misclassified. Review detected entries.
- Notification access cannot retrieve full bank statements or account balances. The displayed balance is calculated only from transactions recorded in MONEYFLOW.
- Android may restrict background delivery or remove notifications. Test with the actual banking/e-wallet apps.
- This is a starter implementation, not a production financial product. Before public release, add a review/confirm inbox, stronger duplicate detection, export/backup, tests, privacy policy, and security review.

## Project structure
- `lib/` Flutter UI, model, parser, SQLite database and method-channel service
- `android/` native Android notification listener and Flutter bridge

## Privacy
All captured notification text is processed and stored on-device. Unparsed notifications are discarded when the app processes the queue. There is no network or analytics integration in this project.
