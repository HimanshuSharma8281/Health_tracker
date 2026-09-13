import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/services/aurora_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuroraApiService Contract & Resilience Tests', () {
    test('BaseUrl returns non-empty valid URL', () {
      expect(AuroraApiService.baseUrl, isNotEmpty);
      expect(AuroraApiService.baseUrl.startsWith('http'), isTrue);
    });

    test('chat returns AuroraChatResult even when backend is offline (resilient fallback)', () async {
      final result = await AuroraApiService.chat(
        uid: 'test_flutter_uid',
        userMessage: 'How many steps should I walk daily?',
      );

      expect(result, isNotNull);
      expect(result.text, isNotEmpty);
      expect(result.updatedHistory, isNotNull);
    });

    test('confirmAction returns false cleanly if server is unreachable', () async {
      final success = await AuroraApiService.confirmAction(
        actionId: 'fake_action_123',
        confirmed: true,
      );

      expect(success, isFalse);
    });
  });
}
