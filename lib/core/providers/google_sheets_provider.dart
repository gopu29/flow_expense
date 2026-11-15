import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_sheets_service.dart';
import '../services/google_drive_sheets_service.dart';

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

final googleDriveSheetsServiceProvider = Provider<GoogleDriveSheetsService>((ref) {
  return GoogleDriveSheetsService();
});

class GoogleAuthStateNotifier extends AsyncNotifier<GoogleSignInAccount?> {
  @override
  Future<GoogleSignInAccount?> build() async {
    final service = ref.watch(googleDriveSheetsServiceProvider);
    return service.signInSilently();
  }

  Future<GoogleSignInAccount?> signIn() async {
    final service = ref.read(googleDriveSheetsServiceProvider);
    final user = await service.signIn();
    state = AsyncData(user);
    return user;
  }

  Future<void> signOut() async {
    final service = ref.read(googleDriveSheetsServiceProvider);
    await service.signOut();
    state = const AsyncData(null);
  }
}

final googleAuthStateProvider =
    AsyncNotifierProvider<GoogleAuthStateNotifier, GoogleSignInAccount?>(
  GoogleAuthStateNotifier.new,
);
