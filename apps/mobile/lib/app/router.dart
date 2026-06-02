import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/camera/presentation/camera_screen.dart';
import 'package:raro_mobile/features/gallery/presentation/gallery_screen.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_1.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_2.dart';
import 'package:raro_mobile/features/permissions/presentation/permissions_screen.dart';
import 'package:raro_mobile/features/preview/presentation/preview_screen.dart';
import 'package:raro_mobile/features/settings/presentation/settings_screen.dart';
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
        builder: (context, state) => CameraScreen(
          onClose: () => context.go(AppScreen.p04Permissions.path),
          onGallery: () => context.go(AppScreen.p07Gallery.path),
          onSettings: () => context.go(AppScreen.p06Settings.path),
        ),
      ),
      GoRoute(
        path: AppScreen.p06Settings.path,
        builder: (context, state) => SettingsScreen(
          onBack: () => context.go(AppScreen.p05Camera.path),
          onSeePlans: () => context.go(AppScreen.p09Paywall.path),
        ),
      ),
      GoRoute(
        path: AppScreen.p07Gallery.path,
        builder: (context, state) => GalleryScreen(
          onBack: () => context.go(AppScreen.p05Camera.path),
          onOpenVideo: (id) => context.go('${AppScreen.p08Preview.path}/$id'),
        ),
      ),
      GoRoute(
        path: AppScreen.p09Paywall.path,
        builder: (context, state) => const _ScreenStub(
          stubKey: Key('paywall_placeholder'),
          label: 'Planos — Task G',
        ),
      ),
      GoRoute(
        path: '${AppScreen.p08Preview.path}/:id',
        builder: (context, state) => PreviewScreen(
          videoId: state.pathParameters['id']!,
          onBack: () => context.go(AppScreen.p07Gallery.path),
        ),
      ),
    ],
  );
}

class _ScreenStub extends StatelessWidget {
  const _ScreenStub({required this.stubKey, required this.label});

  final Key stubKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Scaffold(
      key: stubKey,
      backgroundColor: colors.bgDeep,
      appBar: AppBar(
        backgroundColor: colors.bgDeep,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.ink),
          onPressed: () => context.go(AppScreen.p05Camera.path),
        ),
      ),
      body: Center(
        child: Text(label, style: TextStyle(color: colors.inkDim)),
      ),
    );
  }
}
