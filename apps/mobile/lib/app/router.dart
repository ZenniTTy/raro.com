import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_1.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_2.dart';
import 'package:raro_mobile/features/permissions/presentation/permissions_screen.dart';
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
        builder: (context, state) => PermissionsScreen(
          onGranted: () => context.go(AppScreen.p05Camera.path),
        ),
      ),
      GoRoute(
        path: AppScreen.p05Camera.path,
        builder: (context, state) => const _CameraPlaceholder(),
      ),
    ],
  );
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Scaffold(
      key: const Key('camera_placeholder'),
      backgroundColor: colors.bgDeep,
      body: Center(
        child: Text('Câmera — Task E2', style: TextStyle(color: colors.inkDim)),
      ),
    );
  }
}
