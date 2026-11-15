import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_sheets_service.dart';

final googleSheetsServiceProvider = Provider<GoogleSheetsService>((ref) {
  return GoogleSheetsService();
});

class GoogleSheetsWebhookUrlNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final service = ref.watch(googleSheetsServiceProvider);
    return service.getWebhookUrl();
  }

  Future<void> setUrl(String url) async {
    final service = ref.read(googleSheetsServiceProvider);
    await service.setWebhookUrl(url);
    state = AsyncData(url.trim().isEmpty ? null : url.trim());
  }
}

final googleSheetsWebhookUrlProvider =
    AsyncNotifierProvider<GoogleSheetsWebhookUrlNotifier, String?>(
  GoogleSheetsWebhookUrlNotifier.new,
);
