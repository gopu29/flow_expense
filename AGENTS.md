# Workspace Rules for Quanto Expense Tracker

## 1. Flutter Directory Structure (Feature-First Architecture)
Always adhere strictly to the following directory organization. Never place loose files in `lib/` (except `main.dart`).

```text
lib/
├── core/                         # Shared utilities, constants, theme, database
│   ├── theme/                    # Color tokens, dark theme configuration, typography
│   ├── constants/                # App constants, asset paths, dimensions
│   ├── database/                 # SQLite helpers, migrations, tables
│   ├── utils/                    # Formatters (currency, dates, number parsers)
│   └── widgets/                  # Generic UI components shared across 2+ features
│
├── models/                       # Global domain data models & entities
│   ├── account.dart
│   ├── category.dart
│   ├── transaction.dart
│   └── budget.dart
│
├── features/                     # Feature modules (Feature-First)
│   ├── activity/                 # Timeline screen & daily bar charts
│   │   ├── screens/
│   │   └── widgets/
│   ├── summary/                  # Donut breakdown & category stats
│   │   ├── screens/
│   │   └── widgets/
│   ├── budget/                   # Budget ring & category limit cards
│   │   ├── screens/
│   │   └── widgets/
│   ├── analytics/                # Income vs expense & heatmap calendar
│   │   ├── screens/
│   │   └── widgets/
│   ├── accounts/                 # Account balance list & reordering
│   │   ├── screens/
│   │   └── widgets/
│   ├── quick_input/              # Numpad overlay modal & category picker
│   │   ├── screens/
│   │   └── widgets/
│   ├── voice_logging/            # Voice AI speech input sheet
│   │   ├── screens/
│   │   └── widgets/
│   ├── receipt_scanner/          # Receipt OCR scanner
│   │   ├── screens/
│   │   └── widgets/
│   └── settings/                 # App settings, preferences, Back Tap guide
│       ├── screens/
│       └── widgets/
│
├── routes/                       # Navigation and route definitions
└── main.dart                     # App entry point
```

## 2. File Organization Rules
1. **Never place files directly in `lib/` root**: Only `main.dart` is allowed in `lib/`.
2. **Feature Isolation**: Any screen or widget belonging to a feature MUST be placed inside `lib/features/<feature>/screens/` or `lib/features/<feature>/widgets/`.
3. **Shared Components**: Only reusable components used by 2 or more features belong in `lib/core/widgets/`.
4. **Data Models**: All entities belong in `lib/models/`.
5. **Database Logic**: All SQLite and database queries belong in `lib/core/database/`.
