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
- `sortOrder` (Int, display order among siblings of the same type; added in database version 2)

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
  - High-performance, artifact-free `IndexedStack` navigation and gesture-driven bottom dock with zero tap flash overlays.
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
- [x] **Phase 9: Premium Animation Suite**
  - Continuous sliding active pill indicator with scale bounce on tab selection.
  - Smooth hardware-accelerated `PageView` with `AutomaticKeepAliveClientMixin` tab state preservation.
  - Animated bar growth on the Activity daily spend chart and Analytics dual-bar chart.
  - Sweeping donut chart segments and 360-degree circular budget gauge animation.
  - Reusable `AnimatedAmountText` counting ticker for financial figures across all screens.
  - Staggered entrance animations (`StaggeredEntrance`) for transactions, category bars, and account cards.
  - Tactile micro-interactions: press-down scale feedback (`0.98x`) on account cards, numpad key feedback, and category selection bounce.
- [x] **Phase 10: Visual Polish & Obsidian Fintech Design System**
  - Layered obsidian dual-tone gradients (`#172433 -> #0F1722`, `#16212D -> #0F1722`) replacing flat surfaces across all screen cards and modal sheets.
  - Top-lit hairline border highlights (`#243649`, `#2B3F54`) simulating physical chamfers and ambient edge lighting.
  - High-end Account Details modal sheet with top-shine accent line, squircle category badges per transaction, and semantic currency coloration.
  - Glassmorphic modal sheets across Month Selector, Quick Input, and Voice AI Logger with tactile controls and haptic micro-feedback.
  - Tactile numpad buttons with stateful gradient transitions and cyan accent glows.
- [x] **Phase 11: 3D Mechanical Keypads & Typing/Erasing Displays**
  - Reusable `Numpad3DKey` with realistic 4px extrusion ledge, push-down click physics (`3.5px` compression), specular gradient highlights, and tactile haptics.
  - Oceanic 3D action submit key (`→`) with glowing cyan borders and solid depth ledge.
  - `AnimatedTypingAmountText` digit-by-digit animation: newly typed numbers slide up with an elastic pop-in and fade; erased digits drop down and dissolve smoothly on backspace.
  - Integrated across both the Category Budget allocation keypad sheet and the Quick Input entry modal.
- [x] **Phase 12: System Navigation Insets & Safe Area Constraints**
  - Lifted floating bottom navigation dock and Speed Dial FAB dynamically using `MediaQuery.of(context).padding.bottom` to float cleanly above Android 3-button (`||| [O] <`) and gesture navigation bars.
  - Extended bottom scroll padding across all 5 main screen `ListView`s to `120 + MediaQuery.of(context).padding.bottom`, ensuring bottom items are fully reachable and not hidden behind the floating dock.
  - Enforced `useSafeArea: true` and capped `maxChildSize: 0.88` on all modal bottom sheets (including the Allocate Budget range bar sheet, Month Selector, Quick Input modal, Account Details, Receipt Scanner, and Voice AI Logger) preventing status bar, punch hole, and system header clipping.
  - Resolved Flutter Web font loading 404s by adding explicit `assets/` bundle configuration and native Inter font headers.
- [x] **Phase 13: Bottom Sheet Navigation Bar Clearance**
  - Added `MediaQuery.padding.bottom` to the footer spacing of the Allocate Budget `Confirm` button and the New Account `Create Account` button so they no longer sit behind the Android 3-button navigation bar (Phase 12 `useSafeArea: true` only protects the top of a sheet).
  - Extended bottom list padding on the Budgets and category transactions `DraggableScrollableSheet` lists by the same inset so the last rows stay reachable.
  - Enforced `useSafeArea: true` on the scroll-controlled Category Budget numpad sheet.
- [x] **Phase 14: Quick Input Modal Redesign & Hold-to-Pick Sub-categories**
  - Rebuilt the add modal as a near full-height sheet: a type (`⋮`) button, large centered amount with backspace beside it (hold to clear), Date / Account / Name chips, a main-category rail, and a 3D keypad whose arrow key saves (the separate Save button is gone).
  - `CategoryRail` shows main categories only; tapping selects one, and the selected pill shows the chosen sub-category.
  - `SubcategoryHoldMenu`: holding a main category opens its sub-categories. Slide onto a row and release to select, with direction-aware edge auto-scroll, or release first and then scroll and tap. Holding a category without sub-categories selects it.
  - `CategoryPickerSheet`: four-dot button opens a 4-column category grid with an Expense/Income/Transfer switch, a pencil shortcut to the Category Manager, and the same hold menu on tiles.
  - `NoteEntrySheet`: the Name chip edits the transaction note in a small keyboard sheet and shows the note on the chip.
  - Budget category spend now rolls sub-category transactions up to their main category. No schema change: sub-category transactions keep storing the sub-category id in `categoryId`.
- [x] **Phase 15: Keyboard-Aware Main Shell**
  - `MainShell` hides the floating navigation dock and Speed Dial FAB while the keyboard is open, so they no longer cover the Activity search field.
- [x] **Phase 16: Muted Keypad Enter Key**
  - The 3D keypad enter key is now a muted dark key with a gray arrow, in both the Quick Input and Category Budget keypads.
- [x] **Phase 17: Optional Entry Tools & Simplified Add Button**
  - The main screen now has a single `AddTransactionFab`. The Voice Logger and Receipt Scanner entry points are removed because both are simulated; their sheets stay in the codebase for later.
  - The add modal `⋮` menu opens `EntryFieldsSheet`, which toggles Date, Name, Accounts, Currency converter, Budgets and Calculator. Choices persist through `shared_preferences` via `visibleEntryFieldsProvider`.
  - Calculator adds a `+ − × ÷` key row; `evaluateAmountExpression` applies standard precedence and the arrow key saves the result.
  - `CurrencyConverterSheet` converts offline using a user-entered rate, which is remembered.
  - The Budgets chip shows the money left in the selected category limit, or in the whole budget if the category has no limit. It does not assign transactions to a budget.
- [ ] **Backlog: Real Voice & Receipt Input**
  - `VoiceLoggerSheet` speech capture and `ReceiptScannerSheet` OCR are simulated with sample data and not reachable from the app. Real speech recognition and scan sources were skipped for now.
- [x] **Phase 18: Reorderable Categories Screen**
  - Rebuilt the Categories screen as one list per type (Expense / Income / Transfer). Drag the handle to reorder; tap a category to show its sub-categories plus `+ Sub-category` and `Edit`. A floating `New category` button adds one.
  - `CategoryFormSheet` replaces the old dialog: a small sheet with a name field, emoji button and color button. Edit uses the same sheet, with Delete.
  - Schema: database version 2 adds `categories.sortOrder`. Categories are listed by `sortOrder`, then name, everywhere, including the add-modal rail and grid.
- [x] **Phase 19: Quanto-Style Settings Screen**
  - Rebuilt Settings in Quanto's grouped layout: General (Categories, Currency), Automations (Back tap), Preferences (First day of week, Currency format, Display cents, Haptic feedback), Privacy & security (Hide balances), and Data (Export data, Erase data).
  - `appSettingsProvider` (`lib/core/providers/app_settings_provider.dart`) stores every choice in `shared_preferences`. `main()` loads it before `runApp`.
  - `AppFormatters` now uses the chosen currency symbol, number style (1,234.56 / 12,34,567.89 / 1.234,56 / 1 234,56) and cents setting. `AppFormatters.symbol` replaces `AppConstants.currencySymbol` in input prefixes. Changing a display setting rebuilds the main tabs.
  - Hide balances masks account balances and the total balance (`AnimatedAmountText(isBalance: true)`, `AppFormatters.balance`). Other amounts stay visible.
  - Haptic feedback: every haptic call goes through `AppHaptics`, which does nothing when the toggle is off.
  - First day of week changes the Analytics calendar columns (Monday or Sunday).
  - Export data builds a CSV with category and account names and copies it to the clipboard. Erase data deletes all transactions and budgets and sets account balances to zero, after a confirm dialog. Accounts and categories are kept.
  - Skipped: AI and voice settings, Apple Pay, widgets, control center, subscription, language, reminders, month start day, backup and import.
- [x] **Phase 20: Champagne Gold Accent & Scrollable Filter Sheets**
  - Replaced the cyan/indigo UI accent with champagne gold (`AppColors.accent` `#D9B77E`, light `#EBD3A6`, deep `#A8834A`) for selected states, highlights, chart selection and focused fields. Income green, expense red and each category's own color are unchanged.
  - The Summary filter sheets (period, account, category) and the Analytics account filter now scroll, so long category lists no longer overflow.
- [x] **Phase 21: Quanto-Style Summary Category List**
  - Category rows follow Quanto: a colored squircle badge, the name with a count pill, then the amount and a percentage pill. The wide trailing chevron is gone; a small arrow next to the count shows that a row expands.
  - Expanding shows only sub-categories that have transactions, indented along a thin line in the category color, with smaller badges and the share of the parent. Spending saved on the main category itself shows as a muted "No sub-category" row. A gold "See all N transactions" link replaces the large "View all" box.
