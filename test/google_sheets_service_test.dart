import 'package:flutter_test/flutter_test.dart';
import 'package:flow_expense/core/services/google_sheets_service.dart';
import 'package:flow_expense/models/transaction.dart';
import 'package:flow_expense/models/category.dart';
import 'package:flow_expense/models/account.dart';

void main() {
  group('GoogleSheetsService', () {
    final service = GoogleSheetsService();

    test('appsScriptTemplate contains required endpoints and column headers', () {
      final code = GoogleSheetsService.appsScriptTemplate;
      expect(code.contains('doPost(e)'), isTrue);
      expect(code.contains('doGet(e)'), isTrue);
      expect(code.contains('["ID", "Date", "Type", "Amount", "Category", "Account", "Note"]'), isTrue);
      expect(code.contains('ContentService.MimeType.JSON'), isTrue);
    });

    test('exportTransactions fails gracefully if URL is empty', () async {
      final res = await service.exportTransactions(
        webhookUrl: '',
        transactions: [],
        categories: [],
        accounts: [],
      );
      expect(res.isSuccess, isFalse);
      expect(res.message.contains('not configured'), isTrue);
    });

    test('exportTransactions validates script.google.com domain', () async {
      final res = await service.exportTransactions(
        webhookUrl: 'https://example.com/api',
        transactions: [
          Transaction(
            id: '1',
            amount: 100,
            type: TransactionType.expense,
            categoryId: 'cat',
            accountId: 'acc',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ],
        categories: [const Category(id: 'cat', name: 'Food', iconOrEmoji: '🍔')],
        accounts: [const Account(id: 'acc', name: 'Bank', type: AccountType.bank)],
      );
      expect(res.isSuccess, isFalse);
      expect(res.message.contains('script.google.com'), isTrue);
    });

    test('importTransactions fails gracefully if URL is empty', () async {
      final outcome = await service.importTransactions(
        webhookUrl: '',
        existingTransactionIds: {},
        categories: [],
        accounts: [],
      );
      expect(outcome.result.isSuccess, isFalse);
      expect(outcome.newTransactions.isEmpty, isTrue);
    });
  });
}
