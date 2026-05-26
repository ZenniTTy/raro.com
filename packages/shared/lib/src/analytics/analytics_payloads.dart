import '../enums/buffer_duration.dart';
import '../enums/control_mode.dart';
import '../enums/fps.dart';
import '../enums/lens.dart';
import '../enums/resolution.dart';

class RecordingStartedPayload {
  const RecordingStartedPayload({
    required this.lens,
    required this.resolution,
    required this.fps,
    required this.trigger,
    required this.bufferDuration,
  });

  final Lens lens;
  final Resolution resolution;
  final Fps fps;
  final ControlMode trigger;
  final BufferDuration bufferDuration;

  Map<String, Object?> toMap() => {
    'lens': lens.label,
    'resolution': resolution.label,
    'fps': fps.value,
    'trigger': trigger.name,
    'buffer_duration': bufferDuration.value,
  };
}

class PlanSelectedPayload {
  const PlanSelectedPayload({required this.sku});

  final String sku;

  Map<String, Object?> toMap() => {'sku': sku};
}

class LensSwitchedPayload {
  const LensSwitchedPayload({required this.from, required this.to});

  final Lens from;
  final Lens to;

  Map<String, Object?> toMap() => {'from': from.label, 'to': to.label};
}
