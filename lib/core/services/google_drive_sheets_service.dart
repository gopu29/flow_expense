import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import 'google_sheets_service.dart';

/// Service managing direct Google Account authentication and automated
/// Google Drive & Google Sheets API v4 synchronization without any manual macros.
class GoogleDriveSheetsService {
  static const String _sheetIdKey = 'google_drive_sheet_id';
  static const String _sheetName = 'Transactions';
  static const String _spreadsheetTitle = 'Flow Expense Tracker';
  static const _uuid = Uuid();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/spreadsheets',
    ],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Attempts to restore a previous signed-in Google session silently.
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  /// Triggers the interactive Google Sign-In prompt.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return null;
      rethrow;
    }
  }

  /// Signs out of the Google Account.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Returns the cached Google Sheet ID, if already created.
  Future<String?> getCachedSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sheetIdKey);
  }

  /// Clears the cached Google Sheet ID.
  Future<void> clearCachedSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sheetIdKey);
  }

  /// Returns the browser link to the user's Google Sheet.
  Future<String?> getSpreadsheetUrl() async {
    final id = await getCachedSheetId();
    if (id == null) return null;
    return 'https://docs.google.com/spreadsheets/d/$id/edit';
  }

  /// Finds an existing "Flow Expense Tracker" spreadsheet in the user's Drive,
  /// or automatically creates one with bold headers if it does not exist yet.
  Future<String> getOrCreateSpreadsheet() async {
    final user = _googleSignIn.currentUser;
    if (user == null) {
      throw Exception('Not signed in to Google.');
    }

    final cachedId = await getCachedSheetId();
    final authHeaders = await user.authHeaders;

    // Verify if cached spreadsheet is still reachable
    if (cachedId != null) {
      final verifyRes = await http.get(
        Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$cachedId?fields=spreadsheetId'),
        headers: authHeaders,
      );
      if (verifyRes.statusCode == 200) {
        return cachedId;
      }
      // If deleted or permission lost, remove cache and recreate
      await clearCachedSheetId();
    }

    // Search Drive for existing spreadsheet created by this app
    final searchUri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?q=name=\'$_spreadsheetTitle\' and mimeType=\'application/vnd.google-apps.spreadsheet\' and trashed=false&fields=files(id,name)',
    );

    final searchRes = await http.get(searchUri, headers: authHeaders);
    if (searchRes.statusCode == 200) {
      final data = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final files = data['files'] as List?;
      if (files != null && files.isNotEmpty) {
        final existingId = files.first['id'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sheetIdKey, existingId);
        return existingId;
      }
    }

    // Create new spreadsheet with styled headers
    final createUri = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets');
    final createPayload = {
      'properties': {
        'title': _spreadsheetTitle,
      },
      'sheets': [
        {
          'properties': {
            'title': _sheetName,
            'gridProperties': {
              'frozenRowCount': 1,
            },
          },
          'data': [
            {
              'startRow': 0,
              'startColumn': 0,
              'rowData': [
                {
                  'values': [
                    {'userEnteredValue': {'stringValue': 'ID'}, 'userEnteredFormat': {'textFormat': {'bold': true}}},
                    {'userEnteredValue': {'stringValue': 'Date'}, 'userEnteredFormat': {'textFormat': {'bold': true}}},
                    {'userEnteredValue': {'stringValue': 'Type'}, 'userEnteredFormat': {'textFormat': {'bold': true}}},
                    {'userEnteredValue': {'stringValue': 'Amount'}, 'userEnteredFormat': {'textFormat': {'bold': true}}},
                    {'userEnteredValue': {'stringValue': 'Category'}, 'userEnteredFormat': {'textFormat': {'bold': true}}},
                    {'userEnteredValue': {'stringValue': 'Account'}, 'userEnteredFormat': {'textFormat': {'bold': true}}},
                    {'userEnteredValue': {'stringValue': 'Note'}, 'userEnteredFormat': {'textFormat': {'bold': true}}},
                  ],
                },
              ],
            },
          ],
        },
      ],
    };

    final createRes = await http.post(
      createUri,
      headers: {
        ...authHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(createPayload),
    );

    if (createRes.statusCode >= 200 && createRes.statusCode < 300) {
      final resData = jsonDecode(createRes.body) as Map<String, dynamic>;
      final newId = resData['spreadsheetId'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sheetIdKey, newId);
      return newId;
    } else {
      throw Exception('Failed to create Google Sheet (${createRes.statusCode}): ${createRes.body}');
    }
  }

  /// Automatically exports local transactions to the user's Google Sheet.
  ///
  /// [mode] can be 'append' (adds new rows) or 'replace' (clears existing data and writes all).
  Future<GoogleSheetsSyncResult> exportTransactions({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<Account> accounts,
    String mode = 'append',
  }) async {
    final user = _googleSignIn.currentUser;
    if (user == null) {
      return const GoogleSheetsSyncResult(
        isSuccess: false,
        message: 'Please sign in with Google first.',
      );
    }

    if (transactions.isEmpty) {
      return const GoogleSheetsSyncResult(
        isSuccess: false,
        message: 'No transactions to export.',
      );
    }

    try {
      final sheetId = await getOrCreateSpreadsheet();
      final authHeaders = await user.authHeaders;

      if (mode == 'replace') {
        // Clear all rows below header
        final clearUri = Uri.parse(
          'https://sheets.googleapis.com/v4/spreadsheets/$sheetId/values/$_sheetName!A2:G:clear',
        );
        await http.post(
          clearUri,
          headers: {
            ...authHeaders,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        );
      }

      final catMap = {for (final c in categories) c.id: c.name};
      final accMap = {for (final a in accounts) a.id: a.name};

      final rows = transactions.map((t) {
        return [
          t.id,
          t.date.toIso8601String(),
          t.type.name,
          t.amount,
          catMap[t.categoryId] ?? 'Other',
          accMap[t.accountId] ?? 'Main Account',
          t.note ?? '',
        ];
      }).toList();

      final appendUri = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$sheetId/values/$_sheetName!A1:append?valueInputOption=USER_ENTERED',
      );

      final appendRes = await http.post(
        appendUri,
        headers: {
          ...authHeaders,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'range': '$_sheetName!A1',
          'majorDimension': 'ROWS',
          'values': rows,
        }),
      );

      if (appendRes.statusCode >= 200 && appendRes.statusCode < 300) {
        return GoogleSheetsSyncResult(
          isSuccess: true,
          message: 'Exported ${transactions.length} transactions to your Google Sheet.',
          count: transactions.length,
        );
      } else {
        return GoogleSheetsSyncResult(
          isSuccess: false,
          message: 'Failed to update Google Sheet (${appendRes.statusCode}): ${appendRes.body}',
        );
      }
    } catch (e) {
      return GoogleSheetsSyncResult(
        isSuccess: false,
        message: 'Error syncing with Google Sheets: $e',
      );
    }
  }

  /// Automatically downloads transactions from the user's Google Sheet
  /// and deduplicates them against [existingTransactionIds].
  Future<({GoogleSheetsSyncResult result, List<Transaction> newTransactions})>
      importTransactions({
    required Set<String> existingTransactionIds,
    required List<Category> categories,
    required List<Account> accounts,
  }) async {
    final user = _googleSignIn.currentUser;
    if (user == null) {
      return (
        result: const GoogleSheetsSyncResult(
          isSuccess: false,
          message: 'Please sign in with Google first.',
        ),
        newTransactions: <Transaction>[],
      );
    }

    try {
      final sheetId = await getOrCreateSpreadsheet();
      final authHeaders = await user.authHeaders;

      final getUri = Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$sheetId/values/$_sheetName!A2:G',
      );

      final response = await http.get(getUri, headers: authHeaders);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return (
          result: GoogleSheetsSyncResult(
            isSuccess: false,
            message: 'Failed to fetch rows from Google Sheet (${response.statusCode}): ${response.body}',
          ),
          newTransactions: <Transaction>[],
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawRows = data['values'] as List?;

      if (rawRows == null || rawRows.isEmpty) {
        return (
          result: const GoogleSheetsSyncResult(
            isSuccess: true,
            message: 'Your Google Sheet has no transaction rows yet.',
            count: 0,
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

      for (final row in rawRows) {
        if (row is! List || row.isEmpty) continue;

        final rawId = row.isNotEmpty ? row[0]?.toString().trim() : null;
        final txId = (rawId != null && rawId.isNotEmpty) ? rawId : _uuid.v4();

        if (existingTransactionIds.contains(txId)) {
          skippedDuplicates++;
          continue;
        }

        final rawDate = row.length > 1 ? row[1]?.toString() ?? '' : '';
        final date = DateTime.tryParse(rawDate)?.toLocal() ?? DateTime.now();

        final rawType = row.length > 2 ? row[2]?.toString().toLowerCase() : 'expense';
        final type = TransactionType.values.firstWhere(
          (t) => t.name.toLowerCase() == rawType,
          orElse: () => TransactionType.expense,
        );

        final rawAmount = row.length > 3 ? row[3] : 0.0;
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : (double.tryParse(rawAmount.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);

        if (amount <= 0) continue;

        final catName = row.length > 4 ? row[4]?.toString().trim() ?? '' : '';
        final category = categories.firstWhere(
          (c) => c.name.toLowerCase() == catName.toLowerCase(),
          orElse: () => defaultCategory,
        );

        final accName = row.length > 5 ? row[5]?.toString().trim() ?? '' : '';
        final account = accounts.firstWhere(
          (a) => a.name.toLowerCase() == accName.toLowerCase(),
          orElse: () => defaultAccount,
        );

        final note = row.length > 6 ? row[6]?.toString() : null;

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
          ? 'Imported ${newTxs.length} transactions from Google Sheets${skippedDuplicates > 0 ? " ($skippedDuplicates duplicates skipped)" : ""}.'
          : 'No new transactions found${skippedDuplicates > 0 ? " ($skippedDuplicates duplicates already in local database)" : ""}.';

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
          message: 'Error importing from Google Sheets: $e',
        ),
        newTransactions: <Transaction>[],
      );
    }
  }
}
