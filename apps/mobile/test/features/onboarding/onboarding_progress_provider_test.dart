import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:raro_mobile/features/onboarding/domain/onboarding_step.dart';

class _FakeOnboardingStore implements OnboardingStore {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> markCompleted() async {
    completed = true;
  }
}

void main() {
  late _FakeOnboardingStore store;

  setUp(() {
    store = _FakeOnboardingStore();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [onboardingStoreProvider.overrideWithValue(store)],
    );
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
      expect(store.completed, isFalse);
    });

    test('markCompleted persiste via store e seta step done', () async {
      final container = makeContainer();
      await container.read(onboardingProgressProvider.notifier).markCompleted();

      expect(container.read(onboardingProgressProvider), OnboardingStep.done);
      expect(store.completed, isTrue);
    });
  });
}
