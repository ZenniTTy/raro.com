import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:raro_mobile/features/voice/data/voice_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_repository_provider.g.dart';

@riverpod
VoiceRepository voiceRepository(Ref ref) =>
    PigeonVoiceRepository(VoiceHostApi());
