# TrackMe

> Your money, finally under control.

TrackMe is an **offline-first personal finance manager** for Android and iOS. All your data stays on your device — no cloud, no accounts, no sync. It blends the essentials of a money tracker with smart helpers: an on-device chat assistant, receipt OCR, recurring bills, budgets, loans, and savings goals.

## Features

- **Dashboard** — balance, month-to-date income/expenses, 12-month income-vs-expense chart, spending by category donut, budget progress, upcoming loan payments, and recent activity at a glance.
- **Expenses & Income** — quick add, search, filters, trash/soft-delete, and CSV bulk import with smart column mapping and automatic duplicate skipping.
- **Budgets & Recurring transactions** — monthly budgets with over-spend alerts; daily/weekly/monthly/yearly bills and subscriptions that auto-log expenses when due.
- **Savings Goals** — track progress with milestone notifications at 50% / 75% / 100%.
- **Loans & Repayments** — repayment schedules aligned to your salary day, with due-date notifications.
- **TrackMe Assistant** — a fully offline, rule-based chat that understands English and Filipino/Tagalog. Log expenses and income by typing ("spent ₱150 on lunch"), or ask payday/loan questions. Every action is undoable.
- **Receipt scanner** — on-device Google ML Kit OCR extracts total, date, merchant, and line items from a receipt, then pre-fills an expense.
- **Net Worth & Insights** — net-worth tracking across accounts and monthly/daily analysis.
- **Reports** — monthly and yearly summaries exported to **PDF** or **CSV**.
- **Notifications** — system + in-app alerts for budget exceed, goal completion, and loan due dates.
- **Backup & Restore** — export your full database to JSON and restore it anytime.
- **Multi-currency** — 28 currencies with custom exchange rates; e-wallets (GCash, Maya, Coins.ph) and bank payment methods.
- **Auto-categorization** — keyword rules that sort expenses into categories automatically.

## Privacy

**Your data never leaves this device.** Everything (transactions, budgets, goals, receipts, chat history) is stored in a local SQLite database. TrackMe has no backend, no analytics, and no internet requirement (except optional receipt-library permissions).

## Tech Stack

- **Flutter** (Dart SDK ^3.6.2) — Material 3, light & dark themes
- **State management:** Provider
- **Database:** SQLite via `sqflite` (schema v3)
- **OCR:** Google ML Kit text recognition (on-device)
- **PDF:** `pdf` + `printing`
- **Notifications:** `flutter_local_notifications`
- **Charts:** `fl_chart`

## Getting Started

```bash
flutter pub get
flutter run
```

### Build a release APK

```bash
flutter build apk --release
```

The APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

## Project Structure

```
lib/
├── core/          # theme, styles, constants, loan math, receipt parser
├── data/          # SQLite helper, repository, domain models
├── providers/     # AppState (ChangeNotifier)
├── screens/       # dashboard, transactions, budgets, loans, reports, ...
└── services/      # notifications, OCR, assistant NLP
```

## Tests

```bash
flutter test
```

Unit tests cover loan math, the receipt parser, and the assistant NLP.

## License

All rights reserved.