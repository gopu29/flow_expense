# Mac Build & Google Sheets Integration Guide

This guide covers everything you need to build and run Flow Expense on iOS using a Mac with a **Free Apple ID** (no $99/year developer fee required), set up the native **Back Tap modal overlay**, and sync transactions bidirectionally with a personal **Google Sheet** using Google Apps Script.

---

## 1. Building on Mac with a Free Apple ID

You do not need a paid Apple Developer account to install Flow Expense onto your iPhone from a Mac. The repository has been configured to build with **Personal Teams** (Free Apple accounts) without capability errors.

### 1.1. Prerequisites on Mac
1. Install **Xcode** from the Mac App Store.
2. Install **Flutter SDK** (3.13+ or 3.47+) and add it to your `PATH`.
3. Ensure CocoaPods is installed:
   ```bash
   sudo gem install cocoapods
   ```

### 1.2. Steps to Build and Install
1. **Clone the repository on your Mac**:
   ```bash
   git clone https://github.com/gopu29/flow_expense.git
   cd flow_expense
   flutter pub get
   ```
2. **Open the iOS project in Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. **Configure Signing**:
   - In Xcode's left sidebar, click on **Runner** at the very top.
   - Select the **Signing & Capabilities** tab.
   - Ensure **Automatically manage signing** is checked.
   - Under **Team**, select your **Personal Team** (log in with your free Apple ID if prompted).
   - Under **Bundle Identifier**, if Xcode says the ID is taken, change it slightly (e.g. `com.<yourname>.flowexpense`).
4. **Connect your iPhone**:
   - Plug your iPhone into your Mac via a Lightning / USB-C cable.
   - Unlock your iPhone and tap **Trust this Computer**.
   - In Xcode, select your connected iPhone from the top device dropdown.
5. **Run the App**:
   - Click the **Play / Run** button in Xcode, or run from terminal:
     ```bash
     flutter run -d <your-iphone-id>
     ```
6. **Trust the Developer Profile on iPhone**:
   - On your iPhone, open **Settings ➔ General ➔ VPN & Device Management**.
   - Tap your Apple ID under "Developer App" and tap **Trust**.
   - You can now launch Flow Expense directly on your iPhone!

---

## 2. Preventing the 7-Day Free Account Expiration

Apps signed with a free Apple ID expire after 7 days unless re-signed. You have two convenient options:

1. **Option A (Xcode Wi-Fi Re-run)**:
   - In Xcode ➔ Window ➔ Devices and Simulators, check **Connect via network**.
   - Whenever your iPhone is on the same Wi-Fi as your Mac, building or re-running takes just seconds without plugging in a cable.
2. **Option B (SideStore - Sideloading without a computer)**:
   - Install [SideStore](https://sidestore.io) onto your iPhone once using your Mac.
   - SideStore runs a local WireGuard loopback VPN on your iPhone to automatically re-sign Flow Expense in the background before the 7 days expire—no Mac needed after the initial setup.

---

## 3. iOS Back Tap Native Modal Setup

Flow Expense includes native Swift `AppIntent` integration that enables logging expenses directly from the iOS lock screen, home screen, or inside any app.

```
[Double-Tap iPhone Back] ──> [Native iOS Overlay] ──> [Local SQLite Database]
```

### 3.1. How to Enable Back Tap
1. On your iPhone, open **Settings**.
2. Navigate to **Accessibility ➔ Touch**.
3. Scroll to the very bottom and tap **Back Tap**.
4. Select **Double Tap** (or **Triple Tap**).
5. Scroll down to the **Shortcuts** section and select **Log Flow Expense**.

### 3.2. How It Works Under the Hood
* When triggered, iOS displays a native modal overlay asking for **Amount**, **Category**, and **Note**.
* Tapping **Done** writes the entry locally to `pending_intents.json` inside the app's secure Documents directory (`AddExpenseIntent.swift`).
* When Flow Expense is opened, `PlatformIntentService` automatically reads the pending queue and writes the transactions into local SQLite (`flow_expense.db`).

---

## 4. Google Sheets Two-Way Sync (via Apps Script Macro)

You can sync your local offline transactions with a personal Google Sheet using a free Google Apps Script Web App.

```
[Flow Expense App] <──(JSON POST/GET)──> [Google Apps Script Web App] <──> [Google Sheet]
```

### 4.1. Step-by-Step Google Sheet Setup (3 Minutes)
1. Open [Google Sheets](https://sheets.new) and create a new blank spreadsheet.
2. In the top menu, click **Extensions ➔ Apps Script**.
3. Replace all code in the editor with the script below and click **Save** (`Ctrl+S` / `Cmd+S`):

```javascript
/**
 * Flow Expense - Google Sheets Two-Way Sync Macro
 */
const SHEET_NAME = "Sheet1";

function doPost(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(SHEET_NAME);
    if (!sheet) {
      sheet = ss.insertSheet(SHEET_NAME);
    }
    
    // Create header row if empty
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(["ID", "Date", "Type", "Amount", "Category", "Account", "Note"]);
      sheet.getRange(1, 1, 1, 7).setFontWeight("bold");
    }
    
    const contents = JSON.parse(e.postData.contents);
    const list = Array.isArray(contents) ? contents : (contents.transactions || []);
    
    // Clear old rows if mode is replace
    if (contents.mode === "replace") {
      const lastRow = sheet.getLastRow();
      if (lastRow > 1) {
        sheet.deleteRows(2, lastRow - 1);
      }
    }
    
    let count = 0;
    list.forEach(function(tx) {
      sheet.appendRow([
        tx.id || "",
        tx.date || "",
        tx.type || "expense",
        tx.amount || 0,
        tx.category || "",
        tx.account || "",
        tx.note || ""
      ]);
      count++;
    });
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      count: count,
      message: "Exported " + count + " transactions successfully."
    })).setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAME);
    if (!sheet || sheet.getLastRow() <= 1) {
      return ContentService.createTextOutput(JSON.stringify([]))
        .setMimeType(ContentService.MimeType.JSON);
    }
    
    const rows = sheet.getDataRange().getValues();
    rows.shift(); // Remove header row
    
    const transactions = rows.map(function(r) {
      return {
        id: String(r[0] || ""),
        date: String(r[1] || ""),
        type: String(r[2] || "expense"),
        amount: Number(r[3] || 0),
        category: String(r[4] || ""),
        account: String(r[5] || ""),
        note: String(r[6] || "")
      };
    }).filter(function(tx) {
      return tx.amount > 0;
    });
    
    return ContentService.createTextOutput(JSON.stringify(transactions))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}
```

4. **Deploy as a Web App**:
   - In Apps Script, click the blue **Deploy** button (top right) ➔ **New deployment**.
   - Click the gear icon next to "Select type" and choose **Web app**.
   - Set **Execute as**: **Me** (your Google account).
   - Set **Who has access**: **Anyone**.
   - Click **Deploy**.
   - Review and grant permissions if prompted.
   - **Copy the Web app URL** (starts with `https://script.google.com/macros/s/.../exec`).

### 4.2. Linking Flow Expense to Google Sheets
1. Open **Flow Expense** on your iPhone.
2. Tap the settings gear/nut icon ➔ Scroll to **Data** ➔ Tap **Google Sheets sync**.
3. Paste your Web App URL into the text box and tap **Save URL**.
4. **Available Actions**:
   - **Export to Google Sheet (Append)**: Appends new local transactions to the end of your sheet.
   - **Export to Google Sheet (Replace All)**: Rewrites the entire sheet with your current local database.
   - **Import from Google Sheet**: Downloads transactions from the sheet and inserts them into local SQLite (skipping any transactions with IDs already in the local database to prevent duplicates).

---

## 5. Automated Google Sign-In & Google Drive Setup ($0 Completely Free)

To allow users and customers to connect with a single tap of **"Sign in with Google"** (without pasting any URLs or writing any macro code), you can configure Google Cloud OAuth.

> [!NOTE]
> Google Cloud Console projects, Google Sign-In, Google Drive API, and Google Sheets API v4 are **100% free** for personal and standard application usage. Google provides a generous free tier of 300 requests/minute per project with $0 billing.

### 5.1. Google Cloud Console Configuration (One-Time Developer Setup)
1. Go to the [Google Cloud Console](https://console.cloud.google.com) and create a new project named **Flow Expense**.
2. **Enable APIs**:
   - In the search bar, search for **Google Sheets API** ➔ Click **Enable**.
   - Search for **Google Drive API** ➔ Click **Enable**.
3. **Configure OAuth Consent Screen**:
   - Go to **APIs & Services ➔ OAuth consent screen**.
   - Select **External** ➔ Click **Create**.
   - Fill in:
     - **App name**: `Flow Expense`
     - **User support email**: your Gmail address
     - **Developer contact information**: your Gmail address
   - In **Scopes**, click **Add or Remove Scopes** and select:
     - `.../auth/drive.file` (Per-file access created by this app)
     - `.../auth/spreadsheets` (Google Sheets read/write)
   - In **Test users**, click **Add Users** and add your own Gmail address (e.g. `govindagopuucc@gmail.com`).
4. **Create OAuth Client Credentials**:
   - Go to **APIs & Services ➔ Credentials ➔ Create Credentials ➔ OAuth client ID**:
   - **For Android**:
     - Application type: **Android**
     - Package name: `com.example.flow_expense`
     - SHA-1 certificate fingerprint:
       ```
       D7:2F:08:3B:F6:18:24:EE:13:DF:8B:DE:1A:69:CC:A2:B4:64:F6:ED
       ```
     - Generated Client ID: `970847640730-vo7ri2eksbqegi839au23lj7b373p0ae.apps.googleusercontent.com`
   - **For iOS**:
     - Application type: **iOS**
     - Bundle ID: `com.example.flowExpense`
     - Generated Client ID: `970847640730-v8jdeo8d2ivl86q7vtgbq51jhm5vq6um.apps.googleusercontent.com`
     - iOS URL scheme: `com.googleusercontent.apps.970847640730-v8jdeo8d2ivl86q7vtgbq51jhm5vq6um` (configured in `ios/Runner/Info.plist`)

### 5.2. How the Automated Flow Works
1. When the user taps **Sign In** in Settings ➔ Google Sheets Sync:
2. The app requests scoped permission to create files in Drive (`drive.file`).
3. Flow Expense automatically checks the user's Drive for **"Flow Expense Tracker"**.
4. If it doesn't exist, it creates the spreadsheet with bold headers (`ID, Date, Type, Amount, Category, Account, Note`) and saves the spreadsheet ID in local storage.
5. Every export/import happens directly through Google's official REST API v4.

