import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';
import 'package:raro_shared/raro_shared.dart';

const String _viewType = BridgeChannels.cameraPreview;

class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key, this.showOverlays = true});

  final bool showOverlays;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final platformView = _buildPlatformView();
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final pos = details.localPosition;
            final nx = (pos.dx / constraints.maxWidth).clamp(0.0, 1.0);
            final ny = (pos.dy / constraints.maxHeight).clamp(0.0, 1.0);
            unawaited(
              ref.read(cameraControllerProvider.notifier).focusAt(nx, ny),
            );
          },
          child: showOverlays
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    platformView,
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: RuleOfThirdsPainter()),
                      ),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: ViewportGrainPainter()),
                      ),
                    ),
                  ],
                )
              : platformView,
        );
      },
    );
  }
}
