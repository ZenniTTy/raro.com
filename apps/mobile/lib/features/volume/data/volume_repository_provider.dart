import 'package:raro_mobile/core/native_bridges/generated/volume_api.g.dart';
import 'package:raro_mobile/features/volume/data/volume_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volume_repository_provider.g.dart';

@riverpod
VolumeRepository volumeRepository(Ref ref) =>
    PigeonVolumeRepository(VolumeHostApi());

@riverpod
Future<bool> volumeAvailable(Ref ref) =>
    ref.watch(volumeRepositoryProvider).isAvailable();
