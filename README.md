# MyLedger — Offline Budgeting App

MyLedger is an offline-first personal finance app built with Flutter. It stores all data locally using SQLite and focuses on privacy, fast performance, and an approachable UI for tracking accounts, transactions, budgets, and reports.

## Key Features

- Offline-first storage with local SQLite database
- Account management (checking, savings, credit cards, cash, etc.)
- Transactions: income, expenses, transfers; categories, notes, and dates
- Budgets per category with monthly tracking
- Search, filter and simple reports (charts)
- Calculator-style input for amounts (supports simple expressions)
- Dark mode (Material 3)
- Backup & restore database file
- Optional biometric lock via system biometrics

## Getting Started (Developer)

Prerequisites

- Flutter SDK (recommended 3.10+)
- A device or emulator (Android / iOS) and platform tooling (Android Studio / Xcode)

Clone and install

```bash
git clone https://github.com/yourusername/my_ledger.git
cd my_ledger
flutter pub get
```

Run the app

```bash
flutter run
```

Useful dev commands

```bash
flutter analyze        # static analysis
flutter test           # run tests (if any)
flutter clean          # clear build outputs
flutter pub get        # fetch packages
```

## Database & Migration Notes

The app uses `sqflite` and manages schema migrations in `lib/services/database_service.dart`.

- Migration: In a recent update the database schema was bumped to version `2` to add a `sort_order` column to the `categories` table. On application upgrade the migration code will attempt to alter the table to add the new column with a default of `0`. The migration is written to be safe for existing databases but if you encounter issues you can remove the app data (or delete the `my_ledger.db` file) to recreate the schema.
- Backup: Use the in-app export / import features to move data between devices. When restoring, ensure the DB file matches the expected schema version.

## Troubleshooting

- "no such column: sort_order" — This indicates an older database without the new column. The app includes an on-upgrade step to add this column; if the upgrade fails, delete or replace the database file to recreate it, or restore from a backed-up `.db` file that includes the column.
- "Database locked" — Close other app instances or processes that may access the DB; restart the app.
- Biometrics not available — Ensure platform biometric security is configured on the device.

## Contributing

Contributions are welcome. When submitting changes:

- Run `flutter analyze` and ensure there are no analyzer errors.
- Keep changes focused and include tests where appropriate.

## Developer Tips

- Providers: The app uses Riverpod for state management (see `lib/providers`).
- Database: `lib/services/database_service.dart` centralizes all DB operations and migrations.
- Models: Data models are in `lib/models` and include `toMap()` / `fromMap()` helpers used for persistence.

## License

This project is licensed under the MIT License.

---

If you want any additional sections (screenshots, CI, or development workflows), tell me what you'd like included and I will update the README.

# MyLedger - Offline Budgeting App

MyLedger is a comprehensive, offline-first personal finance application
built with Flutter. It helps you track income, expenses, and net worth
without requiring internet access or sharing your data with third-party
services.

## Features

- **Offline First**: All data is stored locally on your device using
   SQLite.
- **Account Management**: Track unlimited accounts such as Checking,
   Savings, Credit Cards, Cash, and Investments.
- **Transaction Tracking**: Log income, expenses, and transfers with
   categories, notes, and dates.
- **Budgeting**: Set monthly limits per category and track your
   progress visually.
- **Reports & Insights**: Visualize spending habits with interactive
   pie and bar charts.
- **Search & Filter**: Find specific transactions by date, category,
   or keyword.
- **Calculator Input**: Perform math directly in amount fields (for
   example: "12.50 + 5").
- **Dark Mode**: Fully supported Material 3 dark theme.
- **Backup & Restore**: Export your database to a file and restore it
   on any device.
- **Biometric Security**: Optional fingerprint / Face ID lock.

## Getting Started

### Prerequisites

- Flutter SDK (3.10 or higher)
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/my_ledger.git
   cd my_ledger
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Run the app:**

   ```bash
   flutter run
   ```

## Database Schema

The app uses `sqflite` with the following schema:

### `accounts`

| Column | Type | Description |
| --- | --- | --- |
| id | INTEGER PK | Unique ID |
| name | TEXT | Account Name |
| type | INTEGER | Enum Index |
| current_balance | REAL | Live Balance |
| ... | ... | Style props |

### `transactions`

| Column | Type | Description |
| --- | --- | --- |
| id | INTEGER PK | Unique ID |
| account_id | INTEGER FK | Linked Account |
| category_id | INTEGER FK | Linked Category |
| amount | REAL | Transaction Value |
| type | INTEGER | Income/Expense/Transfer |
| date | TEXT | ISO8601 String |
| ... | ... | Metadata |

### `categories`

| Column | Type | Description |
| --- | --- | --- |
| id | INTEGER PK | Unique ID |
| name | TEXT | Category Name |
| type | INTEGER | Income/Expense |
| ... | ... | Style props |

### `budgets`

| Column | Type | Description |
| --- | --- | --- |
| id | INTEGER PK | Unique ID |
| category_id | INTEGER FK | Linked Category |
| amount | REAL | Budget Limit |
| month | INTEGER | Month (1-12) |
| year | INTEGER | Year (YYYY) |

## Troubleshooting

### "Database Locked" Error

If you encounter database lock issues, ensure you are not running multiple
instances of the app and that no other tool is accessing the database file
while the app is running. Restart the app to clear locks.

### Biometrics Not Working

Ensure your device has biometrics enrolled in the system settings. The
app uses the `local_auth` plugin, which requires a secure lock screen to
be configured on the device.

### Backup File Issues

When restoring, make sure the file is a valid `.db` file exported from
MyLedger. Renamed files are acceptable, but the internal SQLite structure
must match the app's schema.

## License

This project is licensed under the MIT License.
