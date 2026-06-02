import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/domain/onboarding_step.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('OnboardingProgress', () {
    test('estado inicial é OnboardingStep.intro', () {
      final container = makeContainer();
      expect(container.read(onboardingProgressProvider), OnboardingStep.intro);
    });

    test('advanceTo muda o step in-memory sem persistir', () async {
      final container = makeContainer();
      container
          .read(onboardingProgressProvider.notifier)
          .advanceTo(OnboardingStep.replay);

      expect(container.read(onboardingProgressProvider), OnboardingStep.replay);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(StorageKeys.onboardingCompleted), isNull);
    });

    test(
      'markCompleted persiste onboardingCompleted=true e seta step done',
      () async {
        final container = makeContainer();
        await container
            .read(onboardingProgressProvider.notifier)
            .markCompleted();

        expect(container.read(onboardingProgressProvider), OnboardingStep.done);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(StorageKeys.onboardingCompleted), isTrue);
      },
    );
  });
}
