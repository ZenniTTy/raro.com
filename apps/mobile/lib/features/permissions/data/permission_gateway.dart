import 'package:permission_handler/permission_handler.dart';

abstract interface class PermissionGateway {
  Future<bool> cameraStatus();
  Future<bool> microphoneStatus();
  Future<bool> requestCamera();
  Future<bool> requestMicrophone();
  Future<bool> openSettings();
}

class PermissionHandlerGateway implements PermissionGateway {
  const PermissionHandlerGateway();

  @override
  Future<bool> cameraStatus() async =>
      (await Permission.camera.status).isGranted;

  @override
  Future<bool> microphoneStatus() async =>
      (await Permission.microphone.status).isGranted;

  @override
  Future<bool> requestCamera() async =>
      (await Permission.camera.request()).isGranted;

  @override
  Future<bool> requestMicrophone() async =>
      (await Permission.microphone.request()).isGranted;

  @override
  Future<bool> openSettings() => openAppSettings();
}
