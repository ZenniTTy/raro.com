import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/domain/camera_error_message.dart';
import 'package:raro_mobile/features/camera/domain/format_catalog.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/application/recording_controller.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_shell_state.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_mobile/features/camera/domain/recording_options_mapper.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';
import 'package:raro_mobile/features/camera/presentation/camera_preview_widget.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/buffer_pill.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/hud_overlay.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/lens_switcher.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/rec_button.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/presentation/widgets/subscription_popup.dart';
import 'package:raro_mobile/features/replay/application/replay_buffer_controller.dart';
import 'package:raro_mobile/features/replay/application/replay_vault_sink.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_shared/raro_shared.dart' show Codec;

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({
    super.key,
    required this.onGallery,
    required this.onSettings,
    required this.onSeePlans,
  });

  final VoidCallback onGallery;
  final VoidCallback onSettings;
  final VoidCallback onSeePlans;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  Timer? _timer;
  Timer? _popupTimer;
  Duration _elapsed = Duration.zero;
  bool _popupShown = false;
  bool _popupVisible = false;
  PigeonFormat _format = const PigeonFormat(
    resolution: Resolution.fhd1080,
    fps: Fps.fps60,
  );

  bool get _is4k60 =>
      _format.resolution == Resolution.uhd4k && _format.fps == Fps.fps60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  Future<void> _startSession() async {
    final notifier = ref.read(cameraControllerProvider.notifier);
    final granted = await notifier.hasPermission();
    if (!granted || !mounted) return;
    final settings = await ref.read(settingsControllerProvider.future);
    final fmt = mapToPigeonFormat(
      resolution: settings.resolution,
      fps: settings.fps,
    );
    if (!mounted) return;
    setState(() => _format = fmt);
    await notifier.start(
      textureId: 0,
      settings: CameraSettings(
        lens: ref.read(cameraShellProvider).lens,
        resolution: fmt.resolution,
        fps: fmt.fps,
      ),
    );
  }

  void _maybeScheduledPopup(bool isSubscribed) {
    if (isSubscribed || _popupShown || _popupTimer != null) return;
    _popupTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _popupVisible = true;
        _popupShown = true;
      });
    });
  }

  void _dismissPopup() => setState(() => _popupVisible = false);

  Future<void> _onSelectLens(LensType lens) async {
    ref.read(cameraShellProvider.notifier).selectLens(lens);
    final isReady =
        ref.read(cameraControllerProvider).value is CameraStateReady;
    if (!isReady) return;
    try {
      await ref.read(cameraControllerProvider.notifier).switchLens(lens);
    } on Object catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .w('switchLens failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _applyFormatToSession(PigeonFormat fmt) async {
    final isReady =
        ref.read(cameraControllerProvider).value is CameraStateReady;
    if (!isReady) return;
    try {
      await ref
          .read(cameraControllerProvider.notifier)
          .setFormat(fmt.resolution, fmt.fps);
    } on Object catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .w('setFormat failed', error: error, stackTrace: stackTrace);
    }
  }

  void _stopElapsedTimer() {
    _timer?.cancel();
    _timer = null;
    _elapsed = Duration.zero;
  }

  Future<void> _onRecTap() async {
    final notifier = ref.read(recordingControllerProvider.notifier);
    final phase = ref.read(recordingControllerProvider);
    final wasActive = phase is RecordingActive || phase is RecordingStarting;
    try {
      if (wasActive) {
        await notifier.stop();
        _stopElapsedTimer();
      } else {
        final replayArmed =
            ref.read(replayBufferControllerProvider) is ReplayBuffering;
        await notifier.start(
          RecordingOptions(
            resolution: _format.resolution,
            fps: _format.fps,
            codec: Codec.h265.label,
            includeReplayPreroll: replayArmed,
          ),
        );
        _elapsed = Duration.zero;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _elapsed += const Duration(seconds: 1));
        });
      }
    } on PlatformException catch (e) {
      _stopElapsedTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cameraErrorMessage(mapPigeonErrorCode(e.code)))),
      );
    } on Object catch (_) {
      _stopElapsedTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falha ao gravar')));
    }
  }

  String _replayErrorMessage(String code) {
    if (code == 'thermalThrottled') {
      return 'Replay pausado: o aparelho está aquecido.';
    }
    return 'Não foi possível salvar o replay.';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _popupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final shell = ref.watch(cameraShellProvider);
    final camAsync = ref.watch(cameraControllerProvider);
    final cameraReady = camAsync.value is CameraStateReady;
    final recordingPhase = ref.watch(recordingControllerProvider);
    final recording =
        recordingPhase is RecordingActive ||
        recordingPhase is RecordingStarting;
    ref.watch(recordingVaultSinkProvider);
    ref.watch(replayVaultSinkProvider);
    ref.watch(replayBufferControllerProvider);

    ref.listen(recordingControllerProvider, (_, next) {
      if (next is RecordingIdle) _stopElapsedTimer();
    });

    ref.listen(settingsControllerProvider, (_, next) {
      final value = next.value;
      if (value == null) return;
      final fmt = mapToPigeonFormat(
        resolution: value.resolution,
        fps: value.fps,
      );
      if (fmt.resolution == _format.resolution && fmt.fps == _format.fps) {
        return;
      }
      if (mounted) setState(() => _format = fmt);
      _applyFormatToSession(fmt);
    });

    ref.listen(cameraControllerProvider, (_, next) {
      if (next.value is CameraStateReady) {
        ref
            .read(replayBufferControllerProvider.notifier)
            .setWindow(shell.bufferDuration.seconds);
      }
    });

    ref.listen(replayBufferControllerProvider, (_, next) {
      if (next is ReplayFailedState && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_replayErrorMessage(next.message))),
        );
      }
    });

    ref.listen(subscriptionControllerProvider, (_, next) {
      final value = next.value;
      if (value != null) _maybeScheduledPopup(value.isSubscribed);
    });
    final subscription = ref.watch(subscriptionControllerProvider).value;
    if (subscription != null) {
      _maybeScheduledPopup(subscription.isSubscribed);
    }

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: Stack(
        children: [
          Column(
            children: [
              const _TopBar(),
              const _GradLine(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _Viewport(
                      cameraReady: cameraReady,
                      recording: recording,
                      elapsed: _elapsed,
                      bufferDuration: shell.bufferDuration,
                      lens: shell.lens,
                      lensLabel: shell.hudLensLabel,
                      resolutionLabel: resolutionLabel(_format.resolution),
                      fpsLabel: fpsLabel(_format.fps),
                      ultraWideEnabled: !_is4k60,
                      onToggleBuffer: () {
                        ref
                            .read(cameraShellProvider.notifier)
                            .toggleBufferDuration();
                        final next = ref
                            .read(cameraShellProvider)
                            .bufferDuration;
                        ref
                            .read(replayBufferControllerProvider.notifier)
                            .setWindow(next.seconds);
                      },
                      onSelectLens: _onSelectLens,
                      onTapHud: widget.onSettings,
                    ),
                  ),
                ),
              ),
              _BottomControls(
                recording: recording,
                onGallery: widget.onGallery,
                onSettings: widget.onSettings,
                onRecTap: _onRecTap,
              ),
            ],
          ),
          if (_popupVisible)
            SubscriptionPopup(
              onSubscribe: () {
                _dismissPopup();
                widget.onSeePlans();
              },
              onLater: _dismissPopup,
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 12),
      child: Center(
        child: Text(
          'RARO',
          style: TextStyle(
            fontFamily: RaroFonts.display,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Viewport extends StatelessWidget {
  const _Viewport({
    required this.cameraReady,
    required this.recording,
    required this.elapsed,
    required this.bufferDuration,
    required this.lens,
    required this.lensLabel,
    required this.resolutionLabel,
    required this.fpsLabel,
    required this.ultraWideEnabled,
    required this.onToggleBuffer,
    required this.onSelectLens,
    required this.onTapHud,
  });

  final bool cameraReady;
  final bool recording;
  final Duration elapsed;
  final BufferDuration bufferDuration;
  final LensType lens;
  final String lensLabel;
  final String resolutionLabel;
  final String fpsLabel;
  final bool ultraWideEnabled;
  final VoidCallback onToggleBuffer;
  final ValueChanged<LensType> onSelectLens;
  final VoidCallback onTapHud;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraReady)
          const Positioned.fill(child: CameraPreviewWidget(showOverlays: false))
        else
          Positioned.fill(child: ColoredBox(color: colors.bgDeep)),
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
                resolutionLabel: resolutionLabel,
                fpsLabel: fpsLabel,
                lensLabel: lensLabel,
                onTap: onTapHud,
              ),
              LensSwitcher(
                selected: lens,
                onSelected: onSelectLens,
                ultraWideEnabled: ultraWideEnabled,
              ),
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
