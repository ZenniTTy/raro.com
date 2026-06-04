import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/data/camera_repository.dart';
import 'package:raro_mobile/features/camera/data/pigeon_camera_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CameraRepository cameraRepository(Ref ref) =>
    PigeonCameraRepository(CameraHostApi());
