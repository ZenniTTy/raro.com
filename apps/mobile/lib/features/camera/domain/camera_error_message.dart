import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';

String cameraErrorMessage(CameraErrorCode? code) {
  switch (code) {
    case CameraErrorCode.sessionInterrupted:
      return 'Câmera interrompida. Tente novamente.';
    case CameraErrorCode.formatUnsupported:
      return 'Resolução indisponível neste aparelho.';
    case CameraErrorCode.permissionDenied:
    case CameraErrorCode.deviceUnavailable:
    case CameraErrorCode.lensUnavailable:
    case CameraErrorCode.sessionFailed:
    case CameraErrorCode.alreadyRunning:
    case CameraErrorCode.notRunning:
    case null:
      return 'Falha ao gravar';
  }
}
