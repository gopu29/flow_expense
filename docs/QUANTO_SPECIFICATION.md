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
- Filter chips: `Search` (with smooth expandable search bar and icon morphing transition), `All transactions` (default selected), `Expenses`, `Income`, `Monthly`, `All accounts`. Smooth animated selection transitions.
- Grouped transaction list by date (`Yesterday`, `Today`, etc.) in unified card containers with category emoji/icon, title, and price.
- Floating Action Dock:
  - Long-press / swipe-to-activate gesture on `+` reveals Voice AI (Mic) and OCR Receipt scanner with haptic feedback.
  - Quick Add (+) transaction button tap opens numpad overlay.

### 3.3. Summary Screen (Screenshot `IMG_6027.PNG`)
- **Atmospheric Background**: Seamless transparent scaffold exposing the midnight gradient background.
- **Top Bar**: Left hexagonal nut/settings button navigating directly to Settings.
- **Hero Donut Chart**: Borderless segmented donut ring with subtle gaps between category arcs. Centered tappable month switcher (`This month ⌵` with `MonthSelectorSheet`) and prominent bold total spend (`₹24,893.32`).
- **Filter Chips**: Horizontal scrolling pill bar (`Expenses`, `Monthly`, `All accounts`, `All categories`) with interactive modal sheets for quick filtering.
- **Unified Category Breakdown Card**: Rounded container (`BorderRadius.circular(22)`) with subtle row dividers, category icon squircle with accent color outline border, title, transaction count pill badge (e.g. `1`, `3`), amount (`₹10,000`), and percentage badge (`40.17%`).
  - **Tap-to-Expand Subcategories**: When a category contains subcategories, clicking toggles a smooth animated accordion with rotating chevron to reveal nested subcategory rows with their individual amounts, percentages, and count badges.
  - **Click-to-View Transactions Sheet**: Clicking on any subcategory, clicking the "View all [Category] transactions" action, or clicking a main category without subcategories opens a bottom sheet showing the complete list of added transactions with dates, accounts, notes, prices, and swipe-to-delete.

### 3.4. Budget Screen (Screenshot `IMG_6028.PNG`)
- **Atmospheric Gradient Background**: Transparent scaffold exposing midnight cyan/slate background.
- **Top Bar**: Left hexagonal nut/settings button, centered active budget profile pill (`Personal`, etc.), right edit button.
- **Hero 360-Degree Circular Progress Ring**:
  - Full circular ring gauge with glowing coral/crimson when overspent, and neon mint/emerald when within budget.
  - Centered tappable timeframe dropdown (`Left this month ⌵` with `MonthSelectorSheet`).
  - Prominent bold remaining balance (e.g. `-₹16,656.59` or `₹5,400.00`) and total limit subtext (`of ₹10,000`).
- **Multiple Budget Profile Manager ("Budgets" Modal Sheet)**:
  - Opened via profile pill or edit icon.
  - Profile switcher with `+` button to create new budgets (e.g., Personal, Business, Vacation, Household).
  - Each profile card shows remaining balance, horizontal progress bar, percentage remaining, and total monthly cap, plus `...` menu to edit name/limit or delete.
- **Category Allocation Manager ("Allocate your budget" Modal Sheet)**:
  - Opened via dashed `+ Add category` button.
  - Overview card showing `% set`, `allocated / total limit`, progress bar, and `₹ left to allocate`.
  - Expense category list with icons, names, tappable allocated amounts, and percentage badges.
  - Full-width `Confirm` pill button to save category limits to the active budget.
- **Allocated Category Cards**: Displays allocated categories on the main budget screen with individual progress bars, spent vs limit, and over/under badges.

### 3.5. Analytics Screen (Screenshots `IMG_6029.PNG`, `IMG_6030.PNG`, `IMG_6031.PNG`)
- **Atmospheric Background & Navigation**: Transparent scaffold seamlessly displaying midnight gradient, top-left hexagonal settings nut button, and horizontal filter pills (`Monthly ⌵`, `All accounts ⌵`).
- **Continuous Unified Vertical Feed**:
  1. **Income vs Expenses Comparison Card**:
     - Dual stat header with rounded green indicator for Income (`₹27,870.4`) and cyan indicator for Expenses (`₹24,893.32`).
     - 6-month dual-bar comparison chart: horizontal mint/cyan dash pills for inactive zero-spend months, tall gradient rounded pill bars for active values, dark capsule highlight for the active month, and right Y-axis scale (`28k`, `14k`, `0`).
  2. **Income Left Card**:
     - Switcher toggle pill between currency amount (`₹2,977.08`) and percentage (`10.7%`).
     - 6-month progression chart with glowing magenta/pink active month pill and translucent column track.
  3. **Calendar Heatmap Matrix**:
     - 7-column squircle grid (`M T W T F S S`) with day numbers and badges: vibrant ocean blue for expense days, mint green text for income days (`+6.66k`, `+107`), dark navy for zero activity, and tap-for-details bottom sheet.
  4. **Insights Teaser Cards**:
     - Frosted glass cards with lock icons and gradient pill buttons: "Unlock recurring insights" and "Unlock budgeting insights".

### 3.6. Accounts Screen (Screenshots `IMG_6032.PNG`, `IMG_6035.PNG`)
- **Atmospheric Background & Top Bar**: Transparent scaffold revealing midnight gradient, top-left hexagonal settings nut button, and top-right circular `+` button for adding new accounts.
- **Hero Aggregated Balance Display**: Clean centered layout with subtitle "Total balance" and prominent bold aggregated amount (e.g., `₹3,004.46`).
- **Reorderable Account Cards**:
  - Dark rounded container cards (`BorderRadius.circular(22)`) with subtle borders.
  - Left squircle emoji/icon container (`BorderRadius.circular(16)`), account name, and bold balance.
  - Right iOS/Quanto drag handle with two horizontal parallel rounded bars (`=`) supporting live drag-and-drop reordering.
- **Interactive Modals**:
  - Sleek "New Account" bottom sheet with name, account type chips, icon carousel, and starting balance.
  - "Account Details" bottom sheet for editing balance, viewing associated transactions, and managing accounts.

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
- **General**: Category Manager (smooth sliding pill tab switcher for Expense/Income/Transfer with directional page slide & fade transitions, tap-to-expand/collapse subcategories with animated chevrons and smooth height transition, dedicated bottom Add Category action button for main categories only, dedicated in-card (+) button for adding scoped subcategories with no classification dropdown), Currency (INR/USD/EUR/etc.), Subscription tier.
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
- [x] **Phase 8: Category Hierarchy & Floating Speed Dial**
  - Full Category & Subcategory CRUD management screen (Expense, Income, Transfer) with custom emojis and color pickers.
  - On-the-fly category/subcategory creation inside the Quick Input modal.
  - Symmetrical 5-tab floating bottom navigation dock.
  - Bottom-right floating Speed Dial FAB: tap opens quick entry numpad; hold/long-press reveals animated Voice AI Logger and Receipt Scanner buttons.
