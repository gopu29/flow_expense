import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';

/// Result status of a Google Sheets export or import operation.
class GoogleSheetsSyncResult {
  final bool isSuccess;
  final String message;
  final int count;

  const GoogleSheetsSyncResult({
    required this.isSuccess,
    required this.message,
    this.count = 0,
  });
}

/// Service handling bidirectional synchronization between local SQLite transactions
/// and a Google Sheet via a lightweight Google Apps Script Web App macro.
class GoogleSheetsService {
  static const String _prefKey = 'google_sheets_webhook_url';
  static const _uuid = Uuid();

  /// Gets the currently configured Google Apps Script Web App URL from preferences.
  Future<String?> getWebhookUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_prefKey);
    return (url != null && url.trim().isNotEmpty) ? url.trim() : null;
  }

  /// Saves the Google Apps Script Web App URL in preferences.
  Future<void> setWebhookUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, url.trim());
  }

  /// Exports local transactions to the configured Google Sheet via HTTP POST.
  ///
  /// [mode] can be 'append' (adds rows to end) or 'replace' (clears existing data and rewrites).
  Future<GoogleSheetsSyncResult> exportTransactions({
    required String webhookUrl,
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<Account> accounts,
    String mode = 'append',
  }) async {
    if (webhookUrl.trim().isEmpty) {
      return const GoogleSheetsSyncResult(
        isSuccess: false,
        message: 'Google Sheets Web App URL is not configured.',
      );
    }

    final uri = Uri.tryParse(webhookUrl.trim());
    if (uri == null || !uri.hasScheme || !uri.host.contains('script.google.com')) {
      return const GoogleSheetsSyncResult(
        isSuccess: false,
        message: 'Invalid Google Apps Script URL. It must begin with https://script.google.com',
      );
    }

    if (transactions.isEmpty) {
      return const GoogleSheetsSyncResult(
        isSuccess: false,
        message: 'No transactions to export.',
      );
    }

    final catMap = {for (final c in categories) c.id: c.name};
    final accMap = {for (final a in accounts) a.id: a.name};

    final payload = {
      'mode': mode,
      'transactions': transactions.map((t) {
        return {
          'id': t.id,
          'date': t.date.toIso8601String(),
          'type': t.type.name,
          'amount': t.amount,
          'category': catMap[t.categoryId] ?? 'Other',
          'account': accMap[t.accountId] ?? 'Main Account',
          'note': t.note ?? '',
        };
      }).toList(),
    };

    try {
      final jsonBody = jsonEncode(payload);
      final response = await _postWithRedirects(uri, jsonBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return GoogleSheetsSyncResult(
          isSuccess: true,
          message: 'Exported ${transactions.length} transactions to Google Sheets.',
          count: transactions.length,
        );
      } else {
        return GoogleSheetsSyncResult(
          isSuccess: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      return GoogleSheetsSyncResult(
        isSuccess: false,
        message: 'Failed to export: $e',
      );
    }
  }

  /// Imports transactions from Google Sheets via HTTP GET and returns the parsed list.
  /// Deduplicates against [existingTransactionIds].
  Future<({GoogleSheetsSyncResult result, List<Transaction> newTransactions})>
      importTransactions({
    required String webhookUrl,
    required Set<String> existingTransactionIds,
    required List<Category> categories,
    required List<Account> accounts,
  }) async {
    if (webhookUrl.trim().isEmpty) {
      return (
        result: const GoogleSheetsSyncResult(
          isSuccess: false,
          message: 'Google Sheets Web App URL is not configured.',
        ),
        newTransactions: <Transaction>[],
      );
    }

    final uri = Uri.tryParse(webhookUrl.trim());
    if (uri == null || !uri.hasScheme || !uri.host.contains('script.google.com')) {
      return (
        result: const GoogleSheetsSyncResult(
          isSuccess: false,
          message: 'Invalid Google Apps Script URL. It must begin with https://script.google.com',
        ),
        newTransactions: <Transaction>[],
      );
    }

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 25));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return (
          result: GoogleSheetsSyncResult(
            isSuccess: false,
            message: 'Failed to fetch from sheet (${response.statusCode}): ${response.body}',
          ),
          newTransactions: <Transaction>[],
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return (
          result: const GoogleSheetsSyncResult(
            isSuccess: false,
            message: 'Unexpected response from Google Sheet. Ensure GET returns an array.',
          ),
          newTransactions: <Transaction>[],
        );
      }

      final defaultAccount = accounts.isNotEmpty
          ? accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first)
          : const Account(id: 'default', name: 'Main Account', type: AccountType.bank);

      final defaultCategory = categories.isNotEmpty
          ? categories.first
          : const Category(id: 'default', name: 'Other', iconOrEmoji: '📦');

      final newTxs = <Transaction>[];
      int skippedDuplicates = 0;

      for (final item in decoded) {
        if (item is! Map) continue;

        final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        if (amount <= 0) continue;

        final rawId = item['id']?.toString().trim();
        final txId = (rawId != null && rawId.isNotEmpty) ? rawId : _uuid.v4();

        // Deduplication
        if (existingTransactionIds.contains(txId)) {
          skippedDuplicates++;
          continue;
        }

        final rawDate = item['date']?.toString() ?? '';
        final date = DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now();

        final rawType = item['type']?.toString().toLowerCase();
        final type = TransactionType.values.firstWhere(
          (t) => t.name.toLowerCase() == rawType,
          orElse: () => TransactionType.expense,
        );

        final catName = item['category']?.toString().trim() ?? '';
        final category = categories.firstWhere(
          (c) => c.name.toLowerCase() == catName.toLowerCase(),
          orElse: () => defaultCategory,
        );

        final accName = item['account']?.toString().trim() ?? '';
        final account = accounts.firstWhere(
          (a) => a.name.toLowerCase() == accName.toLowerCase(),
          orElse: () => defaultAccount,
        );

        final note = item['note']?.toString();

        final tx = Transaction(
          id: txId,
          amount: amount,
          type: type,
          categoryId: category.id,
          accountId: account.id,
          date: date,
          note: (note != null && note.isNotEmpty) ? note : null,
          createdAt: DateTime.now(),
        );

        newTxs.add(tx);
        existingTransactionIds.add(txId);
      }

      final msg = newTxs.isNotEmpty
          ? 'Imported ${newTxs.length} transactions${skippedDuplicates > 0 ? " ($skippedDuplicates duplicates skipped)" : ""}.'
          : 'No new transactions found${skippedDuplicates > 0 ? " ($skippedDuplicates duplicates already in database)" : ""}.';

      return (
        result: GoogleSheetsSyncResult(
          isSuccess: true,
          message: msg,
          count: newTxs.length,
        ),
        newTransactions: newTxs,
      );
    } catch (e) {
      return (
        result: GoogleSheetsSyncResult(
          isSuccess: false,
          message: 'Error importing transactions: $e',
        ),
        newTransactions: <Transaction>[],
      );
    }
  }

  /// Helper handling Google Apps Script 302 redirects upon POST.
  Future<http.Response> _postWithRedirects(Uri uri, String body) async {
    final client = http.Client();
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      // Handle redirect if returned directly
      if (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          response.headers['location'] != null) {
        final redirectUri = Uri.parse(response.headers['location']!);
        return await client.get(redirectUri).timeout(const Duration(seconds: 30));
      }

      return response;
    } finally {
      client.close();
    }
  }

  /// Ready-to-use Google Apps Script code template that users can copy.
  static const String appsScriptTemplate = r'''/**
 * Flow Expense - Google Sheets Sync Macro
 * 
 * Setup instructions:
 * 1. In your Google Sheet, open Extensions > Apps Script.
 * 2. Delete any existing code, paste this entire file, and click Save (Ctrl+S / Cmd+S).
 * 3. Click Deploy > New deployment.
 * 4. Select type: "Web app".
 * 5. Set "Execute as": "Me" (your Google account).
 * 6. Set "Who has access": "Anyone".
 * 7. Click Deploy, grant permissions, and copy the Web App URL.
 * 8. Paste that URL into Flow Expense Settings > Google Sheets Sync.
 */
const SHEET_NAME = "Sheet1";

function doPost(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(SHEET_NAME);
    if (!sheet) {
      sheet = ss.insertSheet(SHEET_NAME);
    }
    
    // Create headers if empty
    if (sheet.getLastRow() === 0) {
      sheet.appendRow(["ID", "Date", "Type", "Amount", "Category", "Account", "Note"]);
      sheet.getRange(1, 1, 1, 7).setFontWeight("bold");
    }
    
    const contents = JSON.parse(e.postData.contents);
    const list = Array.isArray(contents) ? contents : (contents.transactions || []);
    
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
''';
}
