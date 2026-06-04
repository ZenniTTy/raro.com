import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/core/theme/raro_theme_data.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:raro_mobile/features/permissions/application/permission_status_provider.dart';
import 'package:raro_mobile/features/permissions/data/permission_gateway.dart';
import 'package:raro_mobile/features/permissions/presentation/permissions_screen.dart';

class _MockPermissionGateway extends Mock implements PermissionGateway {}

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
  late _MockPermissionGateway gateway;
  late _FakeOnboardingStore onboardingStore;

  setUp(() {
    gateway = _MockPermissionGateway();
    when(gateway.cameraStatus).thenAnswer((_) async => false);
    when(gateway.microphoneStatus).thenAnswer((_) async => false);
    when(gateway.openSettings).thenAnswer((_) async => true);
    onboardingStore = _FakeOnboardingStore();
  });

  Widget harness({VoidCallback? onGranted}) {
    return ProviderScope(
      overrides: [
        permissionGatewayProvider.overrideWithValue(gateway),
        onboardingStoreProvider.overrideWithValue(onboardingStore),
      ],
      child: MaterialApp(
        theme: buildRaroDarkTheme(),
        home: PermissionsScreen(onGranted: onGranted ?? () {}),
      ),
    );
  }

  group('PermissionsScreen', () {
    testWidgets('mostra título "Permissões essenciais"', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('Permissões essenciais'), findsOneWidget);
    });

    testWidgets('mostra section-label "PASSO 1 DE 1"', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('PASSO 1 DE 1'), findsOneWidget);
    });

    testWidgets('mostra cards Câmera e Microfone', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('Câmera'), findsOneWidget);
      expect(find.text('Microfone'), findsOneWidget);
    });

    testWidgets('mostra CTA "Continuar"', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('Continuar com permissões concedidas chama onGranted', (
      tester,
    ) async {
      when(gateway.requestCamera).thenAnswer((_) async => true);
      when(gateway.requestMicrophone).thenAnswer((_) async => true);
      var granted = false;
      await tester.pumpWidget(harness(onGranted: () => granted = true));

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(granted, isTrue);
    });

    testWidgets(
      'Continuar com permissões concedidas marca onboarding completo',
      (tester) async {
        when(gateway.requestCamera).thenAnswer((_) async => true);
        when(gateway.requestMicrophone).thenAnswer((_) async => true);
        await tester.pumpWidget(harness());

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(onboardingStore.completed, isTrue);
      },
    );

    testWidgets('Continuar com permissão negada NÃO chama onGranted', (
      tester,
    ) async {
      when(gateway.requestCamera).thenAnswer((_) async => false);
      when(gateway.requestMicrophone).thenAnswer((_) async => true);
      var granted = false;
      await tester.pumpWidget(harness(onGranted: () => granted = true));

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(granted, isFalse);
    });

    testWidgets(
      'Continuar com permissão negada NÃO marca onboarding completo',
      (tester) async {
        when(gateway.requestCamera).thenAnswer((_) async => false);
        when(gateway.requestMicrophone).thenAnswer((_) async => true);
        await tester.pumpWidget(harness());

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        expect(onboardingStore.completed, isFalse);
      },
    );
  });
}
