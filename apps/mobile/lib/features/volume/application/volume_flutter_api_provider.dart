import 'dart:async';

import 'package:raro_mobile/core/native_bridges/generated/volume_api.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volume_flutter_api_provider.g.dart';

class _VolumeFlutterApi implements VolumeFlutterApi {
  _VolumeFlutterApi({required this.onPressed});

  final void Function(VolumeDirection) onPressed;

  @override
  void onVolumePressed(VolumeDirection direction) => onPressed(direction);
}

@Riverpod(keepAlive: true)
Raw<Stream<VolumeDirection>> volumePressEvents(Ref ref) {
  final pressed = StreamController<VolumeDirection>.broadcast();
  VolumeFlutterApi.setUp(_VolumeFlutterApi(onPressed: pressed.add));
  ref.onDispose(() {
    VolumeFlutterApi.setUp(null);
    pressed.close();
  });
  return pressed.stream;
}
