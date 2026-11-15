import 'package:flutter_test/flutter_test.dart';
import 'package:flow_expense/core/services/google_drive_sheets_service.dart';

void main() {
  group('GoogleDriveSheetsService', () {
    final service = GoogleDriveSheetsService();

    test('exportTransactions without signing in returns friendly error', () async {
      final res = await service.exportTransactions(
        transactions: [],
        categories: [],
        accounts: [],
      );
      expect(res.isSuccess, isFalse);
      expect(res.message.contains('sign in with Google'), isTrue);
    });

    test('importTransactions without signing in returns friendly error', () async {
      final outcome = await service.importTransactions(
        existingTransactionIds: {},
        categories: [],
        accounts: [],
      );
      expect(outcome.result.isSuccess, isFalse);
      expect(outcome.result.message.contains('sign in with Google'), isTrue);
      expect(outcome.newTransactions.isEmpty, isTrue);
    });
  });
}

