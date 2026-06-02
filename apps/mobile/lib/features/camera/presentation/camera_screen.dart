import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/domain/camera_shell_state.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/buffer_pill.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/hud_overlay.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/lens_switcher.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/rec_button.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({
    super.key,
    required this.onClose,
    required this.onGallery,
    required this.onSettings,
  });

  final VoidCallback onClose;
  final VoidCallback onGallery;
  final VoidCallback onSettings;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  void _onRecTap() {
    final wasRecording = ref.read(cameraShellProvider).recording;
    ref.read(cameraShellProvider.notifier).toggleRecording();
    if (wasRecording) {
      _timer?.cancel();
      _timer = null;
      _elapsed = Duration.zero;
    } else {
      _elapsed = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final shell = ref.watch(cameraShellProvider);
    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: Column(
        children: [
          _TopBar(onClose: widget.onClose),
          const _GradLine(),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _Viewport(
                  recording: shell.recording,
                  elapsed: _elapsed,
                  bufferDuration: shell.bufferDuration,
                  lens: shell.lens,
                  lensLabel: shell.hudLensLabel,
                  onToggleBuffer: () => ref
                      .read(cameraShellProvider.notifier)
                      .toggleBufferDuration(),
                  onSelectLens: (lens) =>
                      ref.read(cameraShellProvider.notifier).selectLens(lens),
                  onTapHud: widget.onSettings,
                ),
              ),
            ),
          ),
          _BottomControls(
            recording: shell.recording,
            onGallery: widget.onGallery,
            onSettings: widget.onSettings,
            onRecTap: _onRecTap,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderBright),
              ),
              child: Icon(Icons.close, size: 20, color: colors.ink),
            ),
          ),
          const Text(
            'RARO',
            style: TextStyle(
              fontFamily: RaroFonts.display,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _Viewport extends StatelessWidget {
  const _Viewport({
    required this.recording,
    required this.elapsed,
    required this.bufferDuration,
    required this.lens,
    required this.lensLabel,
    required this.onToggleBuffer,
    required this.onSelectLens,
    required this.onTapHud,
  });

  final bool recording;
  final Duration elapsed;
  final BufferDuration bufferDuration;
  final LensType lens;
  final String lensLabel;
  final VoidCallback onToggleBuffer;
  final ValueChanged<LensType> onSelectLens;
  final VoidCallback onTapHud;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colors.bgDeep),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: ViewportGrainPainter()),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: RuleOfThirdsPainter()),
          ),
        ),
        if (!recording)
          const Center(child: CameraCenterHint())
        else
          Positioned(top: 12, left: 12, child: RecIndicator(elapsed: elapsed)),
        Positioned(
          top: 12,
          right: 12,
          child: BufferPill(duration: bufferDuration, onTap: onToggleBuffer),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              HudInfoBar(
                resolutionLabel: '1080p',
                fpsLabel: '60FPS',
                lensLabel: lensLabel,
                onTap: onTapHud,
              ),
              LensSwitcher(selected: lens, onSelected: onSelectLens),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.recording,
    required this.onGallery,
    required this.onSettings,
    required this.onRecTap,
  });

  final bool recording;
  final VoidCallback onGallery;
  final VoidCallback onSettings;
  final VoidCallback onRecTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundButton(
            key: const Key('camera_gallery_button'),
            icon: Icons.folder_outlined,
            onTap: onGallery,
            colors: colors,
          ),
          RecButton(recording: recording, onTap: onRecTap),
          _RoundButton(
            key: const Key('camera_settings_button'),
            icon: Icons.settings_outlined,
            onTap: onSettings,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _GradLine extends StatelessWidget {
  const _GradLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(gradient: RaroGradients.rainbow),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final VoidCallback onTap;
  final RaroColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colors.bgElev,
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderBright),
        ),
        child: Icon(icon, size: 24, color: colors.ink),
      ),
    );
  }
}
