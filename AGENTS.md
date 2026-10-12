# Workspace Rules & Knowledge Index: Flow Expense (Quanto Clone)

This document is the **single source of truth** for any AI agent interacting with this repository. Read this file first to instantly understand the complete project architecture, documentation index, and strict guidelines.

---

## 1. Project Documentation & Knowledge Index

All detailed specifications, design assets, and screen references live in the `docs/` directory:

- 📘 **Master Specification**: [`docs/QUANTO_SPECIFICATION.md`](docs/QUANTO_SPECIFICATION.md) — Contains the full product requirements, tech stack (Flutter 3.x, SQLite `sqflite`, Swift App Intents for iOS Back Tap), complete screen-by-screen breakdown, and data models (`Account`, `Category`, `Transaction`, `Budget`).
- 🖼️ **UI Mockup Screenshots**: [`docs/screenshots/`](docs/screenshots/)

### Mockup Reference Map
| File | Feature / Screen | Key Visual Elements |
| :--- | :--- | :--- |
| [`IMG_5996.PNG`](docs/screenshots/IMG_5996.PNG) | Back Tap Overview | Back tap trigger overview |
| [`IMG_5997.PNG`](docs/screenshots/IMG_5997.PNG) | Instant Overlay (Amount) | Large amount input field + custom keypad |
| [`IMG_5998.PNG`](docs/screenshots/IMG_5998.PNG) | Instant Overlay (Category) | Category picker with icons/emojis |
| [`IMG_6026.PNG`](docs/screenshots/IMG_6026.PNG) | Activity Screen | Daily spend bar chart, timeline, filters, action dock |
| [`IMG_6027.PNG`](docs/screenshots/IMG_6027.PNG) | Summary Screen | Segmented donut chart, category split list |
| [`IMG_6028.PNG`](docs/screenshots/IMG_6028.PNG) | Budget Screen | Circular progress gauge, category spending limits |
| [`IMG_6029.PNG`](docs/screenshots/IMG_6029.PNG) | Analytics (Income vs Spend) | Dual-bar monthly comparisons |
| [`IMG_6030.PNG`](docs/screenshots/IMG_6030.PNG) | Analytics (Income Left) | Income remaining card with balance/percentage |
| [`IMG_6031.PNG`](docs/screenshots/IMG_6031.PNG) | Analytics (Calendar Heatmap)| Month calendar grid with daily spend badges |
| [`IMG_6032.PNG`](docs/screenshots/IMG_6032.PNG) | Accounts Screen | Total aggregated balance, accounts list |
| [`IMG_6033.PNG`](docs/screenshots/IMG_6033.PNG) | Quick Input Modal | In-app numpad modal, date chip, profile tag |
| [`IMG_6034.PNG`](docs/screenshots/IMG_6034.PNG) | Voice AI Logger | Speech sheet ("Mention transactions in one go") |
| [`IMG_6035.PNG`](docs/screenshots/IMG_6035.PNG) | Account Reordering | Drag handles for accounts |
| [`IMG_6036.PNG`](docs/screenshots/IMG_6036.PNG) | AI Receipt Scanner | Multi-receipt OCR parser |
| [`IMG_6037.PNG`](docs/screenshots/IMG_6037.PNG)–[`IMG_6041.PNG`](docs/screenshots/IMG_6041.PNG) | Settings & Automations | Back Tap setup guide, currency, security, CSV export |

---

## 2. Agent Autonomous Maintenance Rules
1. **Always Read Context First**: An agent arriving at this workspace must read this file (`AGENTS.md`) and consult [`docs/QUANTO_SPECIFICATION.md`](docs/QUANTO_SPECIFICATION.md) before designing or implementing features.
2. **Autonomous Documentation Sync**: Whenever code, data schemas, or features are modified or completed, the agent **MUST automatically update** [`docs/QUANTO_SPECIFICATION.md`](docs/QUANTO_SPECIFICATION.md) (check off roadmap items, record schema changes).
3. **Document New Subsystems**: If a major new subsystem or integration is introduced, create a dedicated document inside `docs/` and link it here in `AGENTS.md`.

---

## 3. Flutter Directory Structure (Feature-First Architecture)
Always adhere strictly to the following directory organization. **Never place loose files in `lib/` (except `main.dart`).**

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

---

## 4. File Organization & Coding Rules
1. **Root `lib/` Isolation**: Only `main.dart` is allowed in `lib/`.
2. **Feature Isolation**: Any screen or widget belonging to a feature MUST be placed inside `lib/features/<feature>/screens/` or `lib/features/<feature>/widgets/`.
3. **Shared Components**: Only reusable components used by 2 or more features belong in `lib/core/widgets/`.
4. **Data Models**: All entities belong in `lib/models/`.
5. **Database Logic**: All SQLite and database queries belong in `lib/core/database/`.

---

## 5. Granular Git Commit & Push Protocol
To maintain a clean repository history, ease review, and actively track progress on GitHub:
1. **Atomic Commits Per Step**: Never bundle multiple unrelated features into one giant commit. Make focused commits after completing each discrete step (e.g., setting up design tokens, adding a database table, building a specific widget/screen).
2. **Conventional Commit Standard**: Use clear conventional commit prefixes:
   - `feat(<feature>)`: for new features or screens (e.g., `feat(theme): add dark mode color tokens`)
   - `style(<feature>)`: for UI styling, fonts, and layout polishing
   - `refactor(<scope>)`: for code reorganization and cleanups
   - `docs(<topic>)`: for documentation and specification updates
3. **Immediate Push**: Run `git push origin main` immediately after each commit so GitHub profile activity reflects real-time progress.

