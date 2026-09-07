import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/core/native_bridges/generated/voice_api.g.dart';
import 'package:raro_mobile/core/native_bridges/generated/volume_api.g.dart';
import 'package:raro_mobile/features/camera/presentation/camera_error_l10n.dart';
import 'package:raro_mobile/features/camera/domain/format_catalog.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/application/camera_flutter_api_provider.dart';
import 'package:raro_mobile/features/camera/application/camera_shell_provider.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/application/recording_controller.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_mobile/features/camera/domain/recording_options_mapper.dart';
import 'package:raro_mobile/features/camera/domain/recording_phase.dart';
import 'package:raro_mobile/features/camera/presentation/camera_preview_widget.dart';
import 'package:raro_mobile/features/camera/presentation/rule_of_thirds_painter.dart';
import 'package:raro_mobile/features/camera/presentation/viewport_grain_painter.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/buffer_pill.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/hud_overlay.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/lens_switcher.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/preroll_confirmation.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/rec_button.dart';
import 'package:raro_mobile/features/camera/presentation/widgets/replay_arm_ring.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/presentation/widgets/subscription_popup.dart';
import 'package:raro_mobile/features/replay/application/replay_buffer_controller.dart';
import 'package:raro_mobile/features/replay/application/replay_vault_sink.dart';
import 'package:raro_mobile/features/replay/domain/replay_buffer_state.dart';
import 'package:raro_mobile/features/settings/application/settings_controller.dart';
import 'package:raro_mobile/features/settings/domain/recording_settings.dart';
import 'package:raro_mobile/features/voice/application/voice_controller.dart';
import 'package:raro_mobile/features/voice/domain/voice_state.dart';
import 'package:raro_mobile/features/voice/presentation/voice_listening_indicator.dart';
import 'package:raro_mobile/features/volume/application/volume_controller.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';
import 'package:raro_shared/raro_shared.dart'
    show BufferDuration, Codec, ControlMode;

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({
    super.key,
    required this.onGallery,
    required this.onSettings,
    required this.onSeePlans,
    this.onPreview,
  });

  final VoidCallback onGallery;
  final VoidCallback onSettings;
  final VoidCallback onSeePlans;
  final ValueChanged<String>? onPreview;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  late final VolumeController _volume;
  Timer? _timer;
  Timer? _popupTimer;
  Duration _elapsed = Duration.zero;
  bool _popupShown = false;
  bool _popupVisible = false;
  bool _recordingHadPreroll = false;
  int? _recordingPrerollSeconds;
  int? _prerollConfirmationSeconds;
  PigeonFormat _format = const PigeonFormat(
    resolution: Resolution.fhd1080,
    fps: Fps.fps60,
  );

  bool get _is4k60 =>
      _format.resolution == Resolution.uhd4k && _format.fps == Fps.fps60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _volume = ref.read(volumeControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startSession();
      ref
          .read(voiceRecordingTriggerProvider.notifier)
          .register(_onVoiceCommand);
      ref
          .read(volumeRecordingTriggerProvider.notifier)
          .register(_onVolumePressed);
      unawaited(_volume.attach());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_volume.attach());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_volume.detach());
    }
  }

  void _onVolumePressed(VolumeDirection direction) {
    _onVoiceCommand(
      direction == VolumeDirection.up ? WakeCommand.start : WakeCommand.stop,
    );
  }

  void _onVoiceCommand(WakeCommand command) {
    final phase = ref.read(recordingControllerProvider);
    if (command == WakeCommand.start && !phase.acceptsStart) return;
    if (command == WakeCommand.stop && !phase.acceptsStop) return;
    unawaited(_onRecTap());
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

  RecordingOptions _buildRecordingOptions() {
    final replayState = ref.read(replayBufferControllerProvider);
    final replayArmed = replayState is ReplayBuffering;
    return RecordingOptions(
      resolution: _format.resolution,
      fps: _format.fps,
      codec: Codec.h265.label,
      includeReplayPreroll: replayArmed,
    );
  }

  Future<void> _onRecTap() async {
    final notifier = ref.read(recordingControllerProvider.notifier);
    final phase = ref.read(recordingControllerProvider);
    if (phase is RecordingStarting) return;
    final wasActive = phase is RecordingActive;
    try {
      if (!wasActive) {
        final replayState = ref.read(replayBufferControllerProvider);
        _recordingHadPreroll = replayState is ReplayBuffering;
        _recordingPrerollSeconds = replayState is ReplayBuffering
            ? replayState.seconds
            : null;
      }
      await notifier.toggle(options: _buildRecordingOptions());
      if (wasActive) {
        _stopElapsedTimer();
      } else {
        _elapsed = Duration.zero;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _elapsed += const Duration(seconds: 1));
        });
      }
    } on PlatformException catch (e) {
      _stopElapsedTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cameraErrorMessage(context, mapPigeonErrorCode(e.code)),
          ),
        ),
      );
    } on Object catch (_) {
      _stopElapsedTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cameraRecordFailed),
        ),
      );
    }
  }

  Timer? _confirmationTimer;

  void _showPrerollConfirmation() {
    final seconds = _recordingPrerollSeconds;
    if (seconds == null || !mounted) return;
    setState(() => _prerollConfirmationSeconds = seconds);
    _confirmationTimer?.cancel();
    _confirmationTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _prerollConfirmationSeconds = null);
    });
  }

  String _replayErrorMessage(String code) {
    final l10n = AppLocalizations.of(context);
    if (code == 'thermalThrottled') {
      return l10n.cameraReplayThermal;
    }
    return l10n.cameraReplaySaveFailed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_volume.detach());
    _timer?.cancel();
    _popupTimer?.cancel();
    _confirmationTimer?.cancel();
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
    final voiceState = ref.watch(voiceControllerProvider);
    final controlMode =
        ref.watch(settingsControllerProvider).value?.controlMode ??
        const RecordingSettings().controlMode;
    final bufferDuration =
        ref.watch(settingsControllerProvider).value?.bufferDuration ??
        const RecordingSettings().bufferDuration;
    final replayState = ref.watch(replayBufferControllerProvider);
    final replayArmed = replayState is ReplayBuffering;
    final replayWindowSeconds = replayState is ReplayBuffering
        ? replayState.seconds
        : bufferDuration.value;

    ref.listen(recordingControllerProvider, (prev, next) {
      if (next is RecordingIdle) {
        _stopElapsedTimer();
        if (prev is RecordingActive && _recordingHadPreroll) {
          if (widget.onPreview == null) {
            _showPrerollConfirmation();
          }
          _recordingHadPreroll = false;
        }
      }
    });

    ref.listen(pendingRecordingProvider, (prev, next) {
      if (next == null || prev?.id == next.id) return;
      widget.onPreview?.call(next.id);
    });

    ref.listen(settingsControllerProvider, (prev, next) {
      final value = next.value;
      if (value == null) return;

      final fmt = mapToPigeonFormat(
        resolution: value.resolution,
        fps: value.fps,
      );
      if (fmt.resolution != _format.resolution || fmt.fps != _format.fps) {
        if (mounted) setState(() => _format = fmt);
        _applyFormatToSession(fmt);
      }

      final prevDuration = prev?.value?.bufferDuration;
      if (value.bufferDuration != prevDuration) {
        ref
            .read(replayBufferControllerProvider.notifier)
            .setWindow(value.bufferDuration.value);
      }
    });

    ref.listen(cameraControllerProvider, (_, next) {
      if (next.value is CameraStateReady) {
        ref
            .read(replayBufferControllerProvider.notifier)
            .setWindow(bufferDuration.value);
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
          Positioned.fill(
            child: _Viewport(
              cameraReady: cameraReady,
              recording: recording,
              elapsed: _elapsed,
              voiceState: voiceState,
              controlMode: controlMode,
              bufferDuration: bufferDuration,
              lens: shell.lens,
              lensLabel: shell.hudLensLabel,
              resolutionLabel: resolutionLabel(_format.resolution),
              fpsLabel: fpsLabel(_format.fps),
              ultraWideEnabled: !_is4k60,
              onToggleBuffer: () => ref
                  .read(settingsControllerProvider.notifier)
                  .toggleBufferDuration(),
              onSelectLens: _onSelectLens,
              onTapHud: widget.onSettings,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                const Spacer(),
                _BottomControls(
                  recording: recording,
                  replayArmed: replayArmed,
                  replayWindowSeconds: replayWindowSeconds,
                  onGallery: widget.onGallery,
                  onSettings: widget.onSettings,
                  onRecTap: _onRecTap,
                ),
              ],
            ),
          ),
          if (_prerollConfirmationSeconds != null)
            PrerollConfirmation(
              key: ValueKey('preroll-confirm-$_prerollConfirmationSeconds'),
              seconds: _prerollConfirmationSeconds!,
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
      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
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
    required this.voiceState,
    required this.controlMode,
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
  final VoiceState voiceState;
  final ControlMode controlMode;
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
    final insets = MediaQuery.viewPaddingOf(context);
    final overlayTop = insets.top + 16;
    final overlayBottom = insets.bottom + 112;
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
        if (recording)
          Positioned(
            top: overlayTop,
            left: 12,
            child: RecIndicator(elapsed: elapsed),
          )
        else if (controlMode == ControlMode.voice)
          Center(child: VoiceListeningIndicator(state: voiceState))
        else
          const Center(child: CameraCenterHint()),
        Positioned(
          top: overlayTop,
          right: 12,
          child: BufferPill(duration: bufferDuration, onTap: onToggleBuffer),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: overlayBottom,
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
    required this.replayArmed,
    required this.replayWindowSeconds,
    required this.onGallery,
    required this.onSettings,
    required this.onRecTap,
  });

  final bool recording;
  final bool replayArmed;
  final int replayWindowSeconds;
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
          ReplayArmRing(
            armed: replayArmed,
            windowSeconds: replayWindowSeconds,
            recording: recording,
            child: RecButton(recording: recording, onTap: onRecTap),
          ),
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
