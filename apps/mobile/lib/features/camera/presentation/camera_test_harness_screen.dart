import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/native_bridges/generated/camera_api.g.dart';
import 'package:raro_mobile/features/camera/application/camera_controller.dart';
import 'package:raro_mobile/features/camera/domain/camera_settings.dart';
import 'package:raro_mobile/features/camera/domain/camera_state.dart';
import 'package:raro_mobile/features/camera/presentation/camera_preview_widget.dart';
import 'package:raro_mobile/features/camera/presentation/lens_chip_row.dart';

class CameraTestHarnessScreen extends ConsumerStatefulWidget {
  const CameraTestHarnessScreen({super.key});

  @override
  ConsumerState<CameraTestHarnessScreen> createState() =>
      _CameraTestHarnessScreenState();
}

class _CameraTestHarnessScreenState
    extends ConsumerState<CameraTestHarnessScreen> {
  Resolution _resolution = Resolution.fhd1080;
  Fps _fps = Fps.fps30;
  LensType _selectedLens = LensType.wide;
  final List<String> _eventLog = <String>[];

  void _logEvent(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _eventLog.insert(0, '$timestamp · $message');
      if (_eventLog.length > 50) {
        _eventLog.removeLast();
      }
    });
  }

  Future<void> _requestPermission() async {
    final notifier = ref.read(cameraControllerProvider.notifier);
    final granted = await notifier.requestPermission();
    _logEvent('requestPermission → $granted');
    if (granted) return;
    final permanentlyDenied = await notifier.isPermissionPermanentlyDenied();
    if (!permanentlyDenied || !mounted) return;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'permission required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'camera access was denied. open settings to enable it.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('open settings'),
          ),
        ],
      ),
    );
    if (shouldOpen == true) {
      await notifier.openSettings();
      _logEvent('openSettings → invoked');
    }
  }

  Future<void> _start() async {
    final stopwatch = Stopwatch()..start();
    final settings = CameraSettings(
      lens: _selectedLens,
      resolution: _resolution,
      fps: _fps,
    );
    await ref
        .read(cameraControllerProvider.notifier)
        .start(textureId: 0, settings: settings);
    stopwatch.stop();
    _logEvent(
      'start lens=${_selectedLens.name} '
      'res=${_resolution.name} fps=${_fps.name} '
      '→ ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  Future<void> _stop() async {
    final stopwatch = Stopwatch()..start();
    await ref.read(cameraControllerProvider.notifier).stop();
    stopwatch.stop();
    _logEvent('stop → ${stopwatch.elapsedMilliseconds}ms');
  }

  Future<void> _switchLens(LensType lens) async {
    final stopwatch = Stopwatch()..start();
    setState(() => _selectedLens = lens);
    await ref.read(cameraControllerProvider.notifier).switchLens(lens);
    stopwatch.stop();
    _logEvent('switchLens ${lens.name} → ${stopwatch.elapsedMilliseconds}ms');
  }

  Future<void> _setFormat() async {
    final stopwatch = Stopwatch()..start();
    await ref
        .read(cameraControllerProvider.notifier)
        .setFormat(_resolution, _fps);
    stopwatch.stop();
    _logEvent(
      'setFormat res=${_resolution.name} fps=${_fps.name} '
      '→ ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(cameraControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'RARO · Camera Test Harness',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: asyncState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'build error: $e',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
                data: (state) => _buildStateBody(state),
              ),
            ),
            _buildControlPanel(asyncState),
            Expanded(flex: 2, child: _buildEventLog()),
          ],
        ),
      ),
    );
  }

  Widget _buildStateBody(CameraState state) {
    return switch (state) {
      CameraStateIdle(:final capabilities) => _buildIdle(capabilities),
      CameraStateInitializing() => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      CameraStateReady() => Column(
        children: [
          const Expanded(child: CameraPreviewWidget(showOverlays: false)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LensChipRow(
              availableLenses: const [LensType.ultraWide, LensType.wide],
              selected: _selectedLens,
              onSelected: _switchLens,
            ),
          ),
        ],
      ),
      CameraStateError(:final code, :final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'error',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                code.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    };
  }

  Widget _buildIdle(CameraCapabilities capabilities) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'idle',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'lenses: ${capabilities.availableLenses.map((l) => l.name).join(', ')}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'res: ${capabilities.supportedResolutions.map((r) => r.name).join(', ')}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'fps: ${capabilities.supportedFps.map((f) => f.name).join(', ')}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(AsyncValue<CameraState> asyncState) {
    final value = asyncState.hasValue ? asyncState.value : null;
    final isReady = value is CameraStateReady;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _btn('permission', _requestPermission),
              _btn('start', _start),
              _btn('stop', isReady ? _stop : null),
              _btn('setFormat', isReady ? _setFormat : null),
            ],
          ),
          const SizedBox(height: 12),
          _segmented<Resolution>(
            label: 'resolution',
            values: const [
              Resolution.hd720,
              Resolution.fhd1080,
              Resolution.uhd4k,
            ],
            selected: _resolution,
            onSelected: (v) {
              setState(() => _resolution = v);
              if (isReady) {
                _setFormat();
              }
            },
            nameOf: (v) => v.name,
          ),
          const SizedBox(height: 8),
          _segmented<Fps>(
            label: 'fps',
            values: const [Fps.fps30, Fps.fps60],
            selected: _fps,
            onSelected: (v) {
              setState(() => _fps = v);
              if (isReady) {
                _setFormat();
              }
            },
            nameOf: (v) => v.name,
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback? onTap) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: ShapeDecoration(
          color: disabled
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.12),
          shape: StadiumBorder(
            side: BorderSide(
              color: Colors.white.withValues(alpha: disabled ? 0.10 : 0.30),
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _segmented<T>({
    required String label,
    required List<T> values,
    required T selected,
    required ValueChanged<T> onSelected,
    required String Function(T) nameOf,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: values.map((v) {
              final isSelected = v == selected;
              return GestureDetector(
                onTap: () => onSelected(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: ShapeDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.4),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                  child: Text(
                    nameOf(v),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEventLog() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'event log',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _eventLog.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _eventLog[i],
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
