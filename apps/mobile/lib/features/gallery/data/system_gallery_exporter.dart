import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raro_mobile/core/native_bridges/generated/gallery_api.g.dart';

abstract interface class SystemGalleryExporter {
  Future<void> exportVideo(String videoPath);
}

class GalleryPermissionDenied implements Exception {
  const GalleryPermissionDenied();
}

class PigeonSystemGalleryExporter implements SystemGalleryExporter {
  PigeonSystemGalleryExporter(this._api, {DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final GalleryHostApi _api;
  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<void> exportVideo(String videoPath) async {
    if (Platform.isAndroid) {
      final sdk = (await _deviceInfo.androidInfo).version.sdkInt;
      if (sdk <= 28) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw const GalleryPermissionDenied();
        }
      }
    }
    await _api.saveVideoToSystemGallery(videoPath);
  }
}
