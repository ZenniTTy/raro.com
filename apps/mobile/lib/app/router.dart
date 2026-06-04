import 'package:go_router/go_router.dart';
import 'package:raro_mobile/features/camera/presentation/camera_screen.dart';
import 'package:raro_mobile/features/checkout/presentation/checkout_screen.dart';
import 'package:raro_mobile/features/gallery/presentation/gallery_screen.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_1.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_2.dart';
import 'package:raro_mobile/features/paywall/domain/plan_type.dart';
import 'package:raro_mobile/features/paywall/presentation/paywall_screen.dart';
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
          onComplete: (completed) => context.go(
            completed
                ? AppScreen.p05Camera.path
                : AppScreen.p02Onboarding1.path,
          ),
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
          onGallery: () => context.go(AppScreen.p07Gallery.path),
          onSettings: () => context.go(AppScreen.p06Settings.path),
          onSeePlans: () => context.go(AppScreen.p09Paywall.path),
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
        builder: (context, state) => PaywallScreen(
          onClose: () => context.go(AppScreen.p05Camera.path),
          onCheckout: (plan) =>
              context.go(AppScreen.p10Checkout.path, extra: plan),
        ),
      ),
      GoRoute(
        path: AppScreen.p10Checkout.path,
        builder: (context, state) => CheckoutScreen(
          plan: state.extra is PlanType
              ? state.extra! as PlanType
              : PlanType.monthly,
          onBack: () => context.go(AppScreen.p09Paywall.path),
          onConfirmed: () => context.go(AppScreen.p05Camera.path),
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
