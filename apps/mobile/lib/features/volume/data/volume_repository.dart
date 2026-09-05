import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:raro_mobile/core/native_bridges/generated/volume_api.g.dart';

abstract interface class VolumeRepository {
  Future<bool> isAvailable();
  Future<void> startListening();
  Future<void> stopListening();
}

class PigeonVolumeRepository implements VolumeRepository {
  PigeonVolumeRepository(this._api);
  final VolumeHostApi _api;
  static final Logger _log = Logger(printer: SimplePrinter());

  @override
  Future<bool> isAvailable() async {
    try {
      return await _api.isAvailable();
    } on PlatformException catch (error) {
      _log.w('volume isAvailable failed: ${error.code}');
      return false;
    }
  }

  @override
  Future<void> startListening() async {
    try {
      await _api.startListening();
    } on PlatformException catch (error) {
      _log.w('volume startListening failed: ${error.code}');
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _api.stopListening();
    } on PlatformException catch (error) {
      _log.w('volume stopListening failed: ${error.code}');
    }
  }
}
