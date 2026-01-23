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
