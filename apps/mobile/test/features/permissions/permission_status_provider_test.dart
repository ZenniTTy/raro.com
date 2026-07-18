import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:raro_mobile/features/permissions/application/permission_status_provider.dart';
import 'package:raro_mobile/features/permissions/data/permission_gateway.dart';

class _MockPermissionGateway extends Mock implements PermissionGateway {}

void main() {
  late _MockPermissionGateway gateway;

  setUp(() {
    gateway = _MockPermissionGateway();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [permissionGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('permissionStatusProvider', () {
    test('granted quando câmera e microfone concedidos', () async {
      when(gateway.cameraStatus).thenAnswer((_) async => true);
      when(gateway.microphoneStatus).thenAnswer((_) async => true);
      final container = makeContainer();

      final status = await container.read(permissionStatusProvider.future);

      expect(status, CamMicStatus.granted);
    });

    test('denied quando câmera negada', () async {
      when(gateway.cameraStatus).thenAnswer((_) async => false);
      when(gateway.microphoneStatus).thenAnswer((_) async => true);
      final container = makeContainer();

      final status = await container.read(permissionStatusProvider.future);

      expect(status, CamMicStatus.denied);
    });

    test('denied quando microfone negado', () async {
      when(gateway.cameraStatus).thenAnswer((_) async => true);
      when(gateway.microphoneStatus).thenAnswer((_) async => false);
      final container = makeContainer();

      final status = await container.read(permissionStatusProvider.future);

      expect(status, CamMicStatus.denied);
    });
  });

  group('PermissionController.request', () {
    test('retorna granted e atualiza estado quando ambos concedidos', () async {
      when(gateway.requestCamera).thenAnswer((_) async => true);
      when(gateway.requestMicrophone).thenAnswer((_) async => true);
      when(gateway.requestNotification).thenAnswer((_) async => true);
      final container = makeContainer();

      final result = await container
          .read(permissionControllerProvider.notifier)
          .request();

      expect(result, CamMicStatus.granted);
      expect(
        container.read(permissionControllerProvider),
        CamMicStatus.granted,
      );
    });

    test('retorna denied quando microfone recusado', () async {
      when(gateway.requestCamera).thenAnswer((_) async => true);
      when(gateway.requestMicrophone).thenAnswer((_) async => false);
      when(gateway.requestNotification).thenAnswer((_) async => true);
      final container = makeContainer();

      final result = await container
          .read(permissionControllerProvider.notifier)
          .request();

      expect(result, CamMicStatus.denied);
      expect(container.read(permissionControllerProvider), CamMicStatus.denied);
    });

    test('estado inicial é pending', () {
      when(gateway.cameraStatus).thenAnswer((_) async => false);
      when(gateway.microphoneStatus).thenAnswer((_) async => false);
      final container = makeContainer();

      expect(
        container.read(permissionControllerProvider),
        CamMicStatus.pending,
      );
    });
  });
}
