# Quanto Clone (Expense Tracker) - Master Product & Architecture Specification

## 1. Overview & Vision
This application is a clone of **Quanto**, an ultra-sleek, modern dark-mode personal finance and expense manager for iOS and Android. 

The standout flagship feature is **seamless, zero-friction expense logging**:
- Triggered instantly via **iOS Back Tap / Shortcuts / Control Center** without opening the full app.
- System overlay prompt allows entering: **Amount ➔ Category / Sub-category ➔ Account ➔ Note**.
- Backed by an in-app companion dashboard with high-end dark visuals, animated charts, budgeting rings, account balances, AI voice logging, and receipt OCR scanning.

---

## 2. Technology Stack & Framework Selection

| Layer | Technology | Rationale |
| :--- | :--- | :--- |
| **Primary Framework** | **Flutter (3.x+)** | High performance (120 fps animations), cross-platform, rich charting ecosystem (`fl_chart`), pixel-perfect dark mode styling. |
| **Primary Language** | **Dart** | Standard language for Flutter. Easy to master for developers coming from TypeScript/Angular. |
| **Native iOS Extension** | **Swift (App Intents & Shortcuts)** | Powers the native system overlay popup (`AppIntent`, `AppShortcutsProvider`) and Back Tap accessibility integration. |
| **Local Database & Storage** | **100% Local SQLite (`sqflite`) + App Groups** | Completely offline & local. **No backend server or API required.** All data (accounts, categories, budgets, transactions) lives on the device. An iOS App Group container allows both the Swift Back Tap overlay and the Flutter app to directly read & write to the same local SQLite database file. |
| **State Management** | **Flutter Riverpod** or **Bloc** | Clean, reactive, testable state separation. |
| **Charting & Visuals** | **`fl_chart`** & Custom Canvas Painters | Custom segmented donut rings, bar charts, and calendar heatmap views matching Quanto. |

---

## 2.1. Project Architecture & Directory Layout

To ensure code maintainability, clean separation of concerns, and ease of navigation, the project strictly adheres to a **Feature-First Clean Architecture**:

```text
lib/
├── core/                         # Shared utilities, services, and cross-cutting concerns
│   ├── theme/                    # Color palettes, typography, theme tokens (Dark Mode)
│   ├── constants/                # App constants, layout dimensions, asset paths
│   ├── database/                 # SQLite helper, tables, migrations (sqflite)
│   └── utils/                    # Formatters (currency, dates, number parsers)
│
├── models/                       # Global Data Models & Entities
│   ├── account.dart
│   ├── category.dart
│   ├── transaction.dart
│   └── budget.dart
│
├── features/                     # Feature-specific modules (Feature-First)
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
├── routes/                       # Navigation & route configurations
└── main.dart                     # App entry point & provider scope initialization
```

### File Placement Rules:
1. **Never dump files into the root of `lib/`** (except `main.dart`).
2. **Feature isolation**: Every new screen, UI component, or widget belongs inside its designated `features/<feature_name>/` folder.
3. **Reusable widgets**: Widgets used across 2 or more distinct features belong in `core/widgets/` or `core/components/`.
4. **Data layer**: Database logic lives exclusively in `core/database/`, with entities in `models/`.

---

## 3. Screen-by-Screen Breakdown (From Screenshots)

### 3.1. Instant Overlay (Screenshots `IMG_5997.PNG`, `IMG_5998.PNG`)
- **Trigger**: Double/Triple Back Tap on iPhone, iOS Action Button, or Siri Shortcut.
- **Step 1 - Amount**:
  - Compact native sheet overlay.
  - Large amount input field with custom iOS keypad + `+/-` toggle and done button.
- **Step 2 - Category Selection**:
  - List of categories with icons/emojis (e.g. `Food AG`, `Chill food`, `Subscription`, `Healthcare`, `Petrol car`, `Repair bike`).
  - Supports sub-categories.
- **Step 3 - Account Selection & Confirmation**:
  - Choice of account (e.g., Main Account, Cash, Credit Card).
  - Instant write to the local database; dismisses overlay.

### 3.2. Activity Screen (Screenshot `IMG_6026.PNG`)
- Top total spending with month switcher dropdown (e.g. `This month ▼ ₹24,893.32`).
- Interactive daily bar chart with baseline dashed line and daily spend bars.
- Filter chips: `Search`, `Expenses`, `Monthly`, `All accounts`, `All categories`.
- Grouped transaction list by date (`Yesterday`, `Today`, etc.) with category emoji/icon, title, and price.
- Floating Action Dock:
  - Voice AI input button (Mic).
  - OCR Receipt scanner button.
  - Quick Add (+) transaction button.

### 3.3. Summary Screen (Screenshot `IMG_6027.PNG`)
- Donut chart with segmented colored arcs for each category.
- Center displays month and total spend (`₹24,893.32`).
- Category breakdown list:
  - Category icon, category name, count badge (e.g. `Savings (1)`, `Transfer (1)`), amount (`₹10,000`), and percentage (`40.17%`).

### 3.4. Budget Screen (Screenshot `IMG_6028.PNG`)
- Top switcher: `Personal` vs other budget profiles + edit budget button.
- Circular progress ring displaying remaining budget or overspend (e.g., `-₹14,893.32 of ₹10,000` in soft neon red/coral).
- `+ Add category` budget limits.

### 3.5. Analytics Screen (Screenshots `IMG_6029.PNG`, `IMG_6030.PNG`, `IMG_6031.PNG`)
- **Income vs Expenses Comparison**: Dual gradient bar charts per month (May to Oct).
- **Income Left Card**: Shows remaining income with balance / percentage toggle.
- **Calendar Heatmap Matrix**: Calendar grid with day numbers and color-coded daily expense badges (e.g., green for positive, blue for expenses).
- **Advanced Insights Cards**: Recurring subscription insights, category spending trends.

### 3.6. Accounts Screen (Screenshots `IMG_6032.PNG`, `IMG_6035.PNG`)
- Total balance aggregated across accounts (e.g., `₹3,004.46`).
- Account card list (e.g., `Main account`, `Cash`, `Credit Card`) with reordering handle (`=`).
- `+` Add account button (modal for account type, name, starting balance, currency).

### 3.7. Full Transaction Input Modal (Screenshot `IMG_6033.PNG`)
- In-app numpad transaction screen.
- Large centered amount display (`₹ 0`) with backspace and next arrow.
- Meta chips:
  - Date selector (e.g. `Today`).
  - Budget/profile tag (e.g. `Personal`).
  - Title/Notes (e.g. `Name`).
- Category icon quick-selector carousel.

### 3.8. Voice AI Logging (Screenshot `IMG_6034.PNG`)
- Fullscreen minimal speech sheet: *"Mention all your transactions in one go"*.
- Actions: Cancel (x), Done checkmark, Keyboard fallback.
- Natural Language Parser extracts Amount, Category, Date, and Account.

### 3.9. AI Receipt & Document Scanner (Screenshot `IMG_6036.PNG`)
- Photos & Collections tabs.
- Multi-receipt selector (up to 10 photos).
- OCR engine parses receipt merchant, date, tax, and total amount.

### 3.10. Settings & Preferences (Screenshots `IMG_6037.PNG`, `IMG_6038.PNG`, `IMG_6039.PNG`, `IMG_6040.PNG`, `IMG_6041.PNG`)
- **General**: Category Manager, Currency (INR/USD/EUR/etc.), Subscription tier.
- **Automations**:
  - **Back Tap Setup guide** (Direct guide to link iOS Settings -> Accessibility -> Back Tap).
  - Apple Pay / SMS automation.
  - Home & Lock screen widgets.
  - Control Center shortcut tile.
- **Preferences**: Language, Voice language, Daily reminder time, Month start day, First day of week, Currency formatting, Display cents toggle, Display merchant logo toggle, Haptic feedback toggle.
- **Privacy & Security**: Hide balances toggle, Biometric lock (FaceID/Fingerprint).
- **Data Management**: Backup & Restore, CSV Data Export, Data Import, Erase data.

---

## 4. Data Models Architecture

### `Account`
- `id` (UUID)
- `name` (String, e.g. "Main Bank", "Cash")
- `type` (Enum: Bank, Cash, CreditCard, Savings, Investment)
- `balance` (Double)
- `currency` (String, default "INR")
- `color` (Hex/Int)
- `icon` (String/Enum)
- `isDefault` (Bool)
- `orderIndex` (Int)

### `Category` & `SubCategory`
- `id` (UUID)
- `parentId` (UUID?, nullable for main categories)
- `name` (String)
- `iconOrEmoji` (String)
- `color` (Hex)
- `type` (Expense | Income | Transfer)

### `Transaction`
- `id` (UUID)
- `amount` (Double)
- `type` (Expense | Income | Transfer)
- `categoryId` (UUID)
- `subCategoryId` (UUID?)
- `accountId` (UUID)
- `toAccountId` (UUID?, for transfers)
- `date` (DateTime)
- `note` (String?)
- `receiptImagePath` (String?)
- `createdAt` (DateTime)

### `Budget`
- `id` (UUID)
- `profileName` (String, e.g. "Personal")
- `monthlyLimit` (Double)
- `categoryLimits` (Map<UUID, Double>)
- `monthYear` (String)

---

## 5. Implementation Roadmap & Phases

- [x] **Phase 1: Project Setup & Design System**
  - Initialize Flutter project with clean dark theme palette, custom fonts, glassmorphism cards, and icons.
- [x] **Phase 2: Database & Core Models**
  - Implement SQLite/Isar local database with repository pattern for Accounts, Categories, and Transactions.
- [x] **Phase 3: iOS Back-Tap Overlay & App Intents**
  - Configure native Swift AppIntent for quick expense addition.
  - Configure App Group shared container for offline sync.
- [x] **Phase 4: Bottom Navigation & 5 Core Screens**
  - Activity (Bar chart, timeline, filters).
  - Summary (Donut chart, category breakdown).
  - Budget (Circular gauge, limits).
  - Analytics (Income vs Expenses, calendar heatmap).
  - Accounts (Multi-account cards, balances, transfers).
- [x] **Phase 5: Quick Input Modals & Controls**
  - In-app custom keypad input modal.
  - Category picker with subcategories and emojis.
- [x] **Phase 6: Advanced Smart Features**
  - Voice AI transaction parsing.
  - Receipt image picker & OCR simulation/integration.
- [x] **Phase 7: Settings, Preferences & Security**
  - Back tap setup instructions page.
  - Biometric lock, currency formatting, CSV export/import, hide balances toggle.
