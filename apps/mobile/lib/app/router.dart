import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_1.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_2.dart';
import 'package:raro_mobile/features/splash/presentation/splash_screen.dart';
import 'package:raro_shared/raro_shared.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppScreen.p01Splash.path,
    routes: [
      GoRoute(
        path: AppScreen.p01Splash.path,
        builder: (context, state) => SplashScreen(
          onComplete: () => context.go(AppScreen.p02Onboarding1.path),
        ),
      ),
      GoRoute(
        path: AppScreen.p02Onboarding1.path,
        builder: (context, state) => OnboardingPage1(
          onNext: () => context.go(AppScreen.p03Onboarding2.path),
          onSkip: () => context.go(AppScreen.p04Permissions.path),
        ),
      ),
      GoRoute(
        path: AppScreen.p03Onboarding2.path,
        builder: (context, state) => OnboardingPage2(
          onNext: () => context.go(AppScreen.p04Permissions.path),
          onSkip: () => context.go(AppScreen.p04Permissions.path),
        ),
      ),
      GoRoute(
        path: AppScreen.p04Permissions.path,
        builder: (context, state) => const _PermissionsPlaceholder(),
      ),
    ],
  );
}

class _PermissionsPlaceholder extends StatelessWidget {
  const _PermissionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Scaffold(
      key: const Key('permissions_placeholder'),
      backgroundColor: colors.bgDeep,
      body: Center(
        child: Text(
          'Permissões — Task E',
          style: TextStyle(color: colors.inkDim),
        ),
      ),
    );
  }
}
