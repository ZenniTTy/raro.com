import 'package:raro_shared/raro_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Identity', () {
    test('bundle id is com.rarocamera', () {
      expect(AppIdentity.bundleId, 'com.rarocamera');
    });
  });

  group('Voice', () {
    test('wake word is Raro (not OkCamera)', () {
      expect(VoiceConfig.wakeWord, 'Raro');
      expect(VoiceConfig.wakeWord.toLowerCase().contains('camera'), isFalse);
    });
  });

  group('Subscription', () {
    test('free trial is 30 days', () {
      expect(SubscriptionConfig.freeTrialDays, 30);
    });

    test('has both monthly and yearly SKUs', () {
      expect(SubscriptionSkus.monthly, contains('monthly'));
      expect(SubscriptionSkus.yearly, contains('yearly'));
    });
  });

  group('Enums', () {
    test('Lens labels match prototype', () {
      expect(Lens.ultraWide.label, '0.5x');
      expect(Lens.wide.label, '1x');
    });

    test('AppLanguage tag', () {
      expect(AppLanguage.ptBr.tag, 'pt-BR');
      expect(AppLanguage.en.tag, 'en');
    });
  });
}
