import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';

abstract interface class VoiceRepository {
  Future<bool> isAvailable();
  Future<void> startListening();
  Future<void> stopListening();
}

class PigeonVoiceRepository implements VoiceRepository {
  PigeonVoiceRepository(this._api);
  final VoiceHostApi _api;

  @override
  Future<bool> isAvailable() => _api.isAvailable();

  @override
  Future<void> startListening() => _api.startListening();

  @override
  Future<void> stopListening() => _api.stopListening();
}
