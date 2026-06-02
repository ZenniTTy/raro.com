import 'package:raro_mobile/features/onboarding/domain/onboarding_step.dart';
import 'package:raro_shared/raro_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_progress_provider.g.dart';

@Riverpod(keepAlive: true)
class OnboardingProgress extends _$OnboardingProgress {
  @override
  OnboardingStep build() => OnboardingStep.intro;

  void advanceTo(OnboardingStep step) {
    state = step;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingCompleted, true);
    state = OnboardingStep.done;
  }
}
