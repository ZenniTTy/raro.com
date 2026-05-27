import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/presentation/focus_ring_overlay.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';
import 'package:raro_shared/raro_shared.dart';

const String _viewType = BridgeChannels.cameraPreview;

class CameraPreviewWidget extends ConsumerStatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  ConsumerState<CameraPreviewWidget> createState() =>
      _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends ConsumerState<CameraPreviewWidget> {
  Offset? _focus;

  Widget _buildPlatformView() {
    if (Platform.isIOS) {
      return const UiKitView(
        viewType: _viewType,
        creationParams: <String, Object?>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    if (Platform.isAndroid) {
      return const AndroidView(
        viewType: _viewType,
        creationParams: <String, Object?>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) async {
            final pos = details.localPosition;
            setState(() => _focus = pos);
            final nx = (pos.dx / constraints.maxWidth).clamp(0.0, 1.0);
            final ny = (pos.dy / constraints.maxHeight).clamp(0.0, 1.0);
            await ref.read(cameraControllerProvider.notifier).focusAt(nx, ny);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPlatformView(),
              const IgnorePointer(
                child: CustomPaint(painter: RuleOfThirdsPainter()),
              ),
              const IgnorePointer(
                child: CustomPaint(painter: ViewportGrainPainter()),
              ),
              if (_focus != null)
                FocusRingOverlay(key: ValueKey(_focus), position: _focus!),
            ],
          ),
        );
      },
    );
  }
}
