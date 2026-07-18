import 'package:flutter/widgets.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

String cameraErrorMessage(BuildContext context, CameraErrorCode? code) {
  final l10n = AppLocalizations.of(context);
  switch (code) {
    case CameraErrorCode.sessionInterrupted:
      return l10n.cameraSessionInterrupted;
    case CameraErrorCode.formatUnsupported:
      return l10n.cameraFormatUnsupported;
    case CameraErrorCode.permissionDenied:
    case CameraErrorCode.deviceUnavailable:
    case CameraErrorCode.lensUnavailable:
    case CameraErrorCode.sessionFailed:
    case CameraErrorCode.alreadyRunning:
    case CameraErrorCode.notRunning:
    case null:
      return l10n.cameraRecordFailed;
  }
}
