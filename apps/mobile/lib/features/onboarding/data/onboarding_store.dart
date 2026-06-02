import 'package:raro_shared/raro_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStore {
  Future<void> markCompleted();
  Future<bool> isCompleted();
}

class SharedPreferencesOnboardingStore implements OnboardingStore {
  const SharedPreferencesOnboardingStore();

  @override
  Future<void> markCompleted() async {
    await SharedPreferencesAsync().setBool(
      StorageKeys.onboardingCompleted,
      true,
    );
  }

  @override
  Future<bool> isCompleted() async {
    return await SharedPreferencesAsync().getBool(
          StorageKeys.onboardingCompleted,
        ) ??
        false;
  }
}
