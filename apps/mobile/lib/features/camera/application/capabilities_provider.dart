import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capabilities_provider.g.dart';

@Riverpod(keepAlive: true)
class Capabilities extends _$Capabilities {
  @override
  List<FormatCapability> build() => const [];

  void update(List<FormatCapability> formats) {
    state = formats;
  }
}
