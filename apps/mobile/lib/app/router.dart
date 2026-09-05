import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/presentation/camera_screen.dart';
import 'package:raro_mobile/features/checkout/presentation/checkout_screen.dart';
import 'package:raro_mobile/features/gallery/presentation/gallery_screen.dart';
import 'package:raro_mobile/features/legal/domain/legal_document.dart';
import 'package:raro_mobile/features/legal/presentation/legal_document_screen.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_1.dart';
import 'package:raro_mobile/features/onboarding/presentation/onboarding_page_2.dart';
import 'package:raro_mobile/features/paywall/domain/paywall_args.dart';
import 'package:raro_mobile/features/paywall/domain/paywall_intent.dart';
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
          onPreview: (id) => context.go(_previewLocation(id, fromCamera: true)),
        ),
      ),
      GoRoute(
        path: AppScreen.p06Settings.path,
        builder: (context, state) => SettingsScreen(
          onBack: () => context.go(AppScreen.p05Camera.path),
          onSeePlans: () => context.go(AppScreen.p09Paywall.path),
          onTerms: () => context.push(AppScreen.p11Terms.path),
          onPrivacy: () => context.push(AppScreen.p12Privacy.path),
        ),
      ),
      GoRoute(
        path: AppScreen.p07Gallery.path,
        builder: (context, state) => GalleryScreen(
          onBack: () => context.go(AppScreen.p05Camera.path),
          onOpenVideo: (id) =>
              context.go(_previewLocation(id, fromCamera: false)),
        ),
      ),
      GoRoute(
        path: AppScreen.p09Paywall.path,
        builder: (context, state) {
          final args = _paywallArgs(state.extra);
          return PaywallScreen(
            intent: args.intent,
            onClose: () => _onPaywallClosed(context, args),
            onUnlocked: () => _onPaywallUnlocked(context, args),
            onTerms: () => context.push(AppScreen.p11Terms.path),
            onPrivacy: () => context.push(AppScreen.p12Privacy.path),
            onCheckout: (plan) => context.go(
              AppScreen.p10Checkout.path,
              extra: CheckoutArgs(plan: plan, paywall: args),
            ),
          );
        },
      ),
      GoRoute(
        path: AppScreen.p10Checkout.path,
        builder: (context, state) {
          final args = _checkoutArgs(state.extra);
          return CheckoutScreen(
            plan: args.plan,
            onBack: () =>
                context.go(AppScreen.p09Paywall.path, extra: args.paywall),
            onConfirmed: () => context.go(AppScreen.p05Camera.path),
            onPendingSaved: args.paywall.intent == PaywallIntent.save
                ? (id) => context.go(_previewLocation(id, fromCamera: false))
                : null,
          );
        },
      ),
      GoRoute(
        path: AppScreen.p11Terms.path,
        builder: (context, state) => LegalDocumentScreen(
          document: LegalDocument.terms,
          onBack: () => _onLegalBack(context),
        ),
      ),
      GoRoute(
        path: AppScreen.p12Privacy.path,
        builder: (context, state) => LegalDocumentScreen(
          document: LegalDocument.privacy,
          onBack: () => _onLegalBack(context),
        ),
      ),
      GoRoute(
        path: '${AppScreen.p08Preview.path}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final fromCamera = state.uri.queryParameters['from'] == 'camera';
          return PreviewScreen(
            videoId: id,
            onBack: () => context.go(
              fromCamera ? AppScreen.p05Camera.path : AppScreen.p07Gallery.path,
            ),
            onNeedPremium: (intent) => context.go(
              AppScreen.p09Paywall.path,
              extra: PaywallArgs(
                intent: intent,
                videoId: id,
                fromCamera: fromCamera,
              ),
            ),
          );
        },
      ),
    ],
  );
}

String _previewLocation(String id, {required bool fromCamera}) {
  final path = '${AppScreen.p08Preview.path}/$id';
  return fromCamera ? '$path?from=camera' : path;
}

PaywallArgs _paywallArgs(Object? extra) {
  if (extra is PaywallArgs) return extra;
  return const PaywallArgs();
}

CheckoutArgs _checkoutArgs(Object? extra) {
  if (extra is CheckoutArgs) return extra;
  if (extra is PlanType) return CheckoutArgs(plan: extra);
  return const CheckoutArgs(plan: PlanType.monthly);
}

void _onLegalBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(AppScreen.p06Settings.path);
}

void _onPaywallClosed(BuildContext context, PaywallArgs args) {
  if (args.intent == PaywallIntent.save) {
    unawaited(
      ProviderScope.containerOf(
        context,
      ).read(pendingRecordingProvider.notifier).discard(),
    );
    context.go(AppScreen.p05Camera.path);
    return;
  }
  if (args.intent == PaywallIntent.share && args.videoId != null) {
    context.go(_previewLocation(args.videoId!, fromCamera: args.fromCamera));
    return;
  }
  context.go(AppScreen.p05Camera.path);
}

void _onPaywallUnlocked(BuildContext context, PaywallArgs args) {
  if (args.videoId != null) {
    context.go(
      _previewLocation(
        args.videoId!,
        fromCamera: args.intent == PaywallIntent.save ? false : args.fromCamera,
      ),
    );
    return;
  }
  context.go(AppScreen.p05Camera.path);
}
