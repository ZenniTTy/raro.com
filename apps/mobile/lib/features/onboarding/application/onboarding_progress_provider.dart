import 'package:raro_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:raro_mobile/features/onboarding/domain/onboarding_step.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_progress_provider.g.dart';

@Riverpod(keepAlive: true)
OnboardingStore onboardingStore(Ref ref) =>
    const SharedPreferencesOnboardingStore();

@Riverpod(keepAlive: true)
class OnboardingProgress extends _$OnboardingProgress {
  @override
  OnboardingStep build() => OnboardingStep.intro;

  void advanceTo(OnboardingStep step) {
    state = step;
  }

  Future<void> markCompleted() async {
    await ref.read(onboardingStoreProvider).markCompleted();
    state = OnboardingStep.done;
  }
}
