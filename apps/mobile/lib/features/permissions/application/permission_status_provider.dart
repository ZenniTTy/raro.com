import 'package:raro_mobile/features/permissions/data/permission_gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_status_provider.g.dart';

enum CamMicStatus { pending, granted, denied }

@Riverpod(keepAlive: true)
PermissionGateway permissionGateway(Ref ref) =>
    const PermissionHandlerGateway();

@riverpod
Future<CamMicStatus> permissionStatus(Ref ref) async {
  final gateway = ref.watch(permissionGatewayProvider);
  final cam = await gateway.cameraStatus();
  final mic = await gateway.microphoneStatus();
  if (cam && mic) return CamMicStatus.granted;
  return CamMicStatus.denied;
}

@Riverpod(keepAlive: true)
class PermissionController extends _$PermissionController {
  @override
  CamMicStatus build() => CamMicStatus.pending;

  Future<CamMicStatus> request() async {
    final gateway = ref.read(permissionGatewayProvider);
    final cam = await gateway.requestCamera();
    final mic = await gateway.requestMicrophone();
    final result = cam && mic ? CamMicStatus.granted : CamMicStatus.denied;
    state = result;
    return result;
  }

  Future<void> openSettings() async {
    await ref.read(permissionGatewayProvider).openSettings();
  }
}
