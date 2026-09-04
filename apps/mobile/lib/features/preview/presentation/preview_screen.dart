import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/logging/app_logger.dart';
import 'package:raro_mobile/core/subscription/billing_gateway.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/camera/application/pending_recording_controller.dart';
import 'package:raro_mobile/features/camera/application/persist_outcome.dart';
import 'package:raro_mobile/features/camera/application/persist_recording_scope.dart';
import 'package:raro_mobile/features/gallery/application/video_list_provider.dart';
import 'package:raro_mobile/features/gallery/domain/video_entity.dart';
import 'package:raro_mobile/features/paywall/application/subscription_controller.dart';
import 'package:raro_mobile/features/paywall/domain/paywall_intent.dart';
import 'package:raro_mobile/features/preview/data/share_gateway_provider.dart';
import 'package:raro_mobile/features/preview/domain/preview_metadata.dart';
import 'package:raro_mobile/features/preview/presentation/widgets/preview_viewport.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({
    super.key,
    required this.videoId,
    required this.onBack,
    this.onNeedPremium,
  });

  final String videoId;
  final VoidCallback onBack;
  final ValueChanged<PaywallIntent>? onNeedPremium;

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  VideoEntity? _pinned;
  bool _busy = false;

  Future<void> _handleBack() async {
    final pending = ref.read(pendingRecordingProvider);
    if (pending != null && pending.id == widget.videoId) {
      await ref.read(pendingRecordingProvider.notifier).discard();
    }
    widget.onBack();
  }

  Future<bool> _hasPremium() async {
    final billing = ref.read(billingGatewayProvider);
    try {
      await billing.ensureConfigured();
      return (await billing.getCustomer()).hasPremium;
    } on BillingException {
      return false;
    }
  }

  Future<void> _onSave() async {
    if (_busy) return;
    final pending = ref.read(pendingRecordingProvider);
    if (pending == null || pending.id != widget.videoId) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      if (!await _hasPremium()) {
        widget.onNeedPremium?.call(PaywallIntent.save);
        return;
      }
      final outcome = await (await persistRecordingFor(ref))(pending);
      if (!mounted) return;
      switch (outcome) {
        case PersistNeedsPremium():
          widget.onNeedPremium?.call(PaywallIntent.save);
        case PersistSucceeded(:final entity):
          ref.read(pendingRecordingProvider.notifier).clearKept();
          ref.invalidate(videoListProvider);
          setState(() => _pinned = entity);
        case PersistFailed():
          _showSnack(l10n.previewSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onShare(BuildContext buttonContext) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    if (!await _hasPremium()) {
      widget.onNeedPremium?.call(PaywallIntent.share);
      return;
    }
    if (!mounted) return;
    final video = _resolveVideo();
    final path = video?.filePath;
    if (path == null || !File(path).existsSync()) {
      _showSnack(l10n.previewShareFailed);
      return;
    }
    try {
      await ref.read(shareGatewayProvider).shareFile(path, origin: origin);
    } on Object catch (error) {
      ref.read(appLoggerProvider).w('share failed error=$error');
      if (mounted) {
        _showSnack(l10n.previewShareFailed);
      }
    }
  }

  VideoEntity? _resolveVideo() {
    final pending = ref.read(pendingRecordingProvider);
    if (pending != null && pending.id == widget.videoId) {
      return pending.asEntity;
    }
    if (_pinned?.id == widget.videoId) return _pinned;
    final videos = ref.read(videoListProvider).value ?? const <VideoEntity>[];
    return videos.where((VideoEntity v) => v.id == widget.videoId).firstOrNull;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final pending = ref.watch(pendingRecordingProvider);
    final videosAsync = ref.watch(videoListProvider);
    final isPending = pending != null && pending.id == widget.videoId;
    final video = isPending
        ? pending.asEntity
        : (_pinned?.id == widget.videoId
              ? _pinned
              : (videosAsync.value ?? const <VideoEntity>[])
                    .where((VideoEntity v) => v.id == widget.videoId)
                    .firstOrNull);

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: video != null
          ? _PreviewBody(
              video: video,
              isPending: isPending,
              onBack: _handleBack,
              onSave: _onSave,
              onShare: _onShare,
            )
          : videosAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _NotFound(onBack: widget.onBack),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.video,
    required this.isPending,
    required this.onBack,
    required this.onSave,
    required this.onShare,
  });

  final VideoEntity video;
  final bool isPending;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final ValueChanged<BuildContext> onShare;

  @override
  Widget build(BuildContext context) {
    final meta = PreviewMetadata.fromVideo(video);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(
            title:
                '${AppLocalizations.of(context).previewVideoTitle} · '
                '${meta.titleLabel}',
            onBack: onBack,
            onShare: onShare,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: PreviewViewport(video: video),
                  ),
                  const SizedBox(height: 20),
                  _InfoCard(meta: meta),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _BottomActions(
            isPending: isPending,
            onSave: onSave,
            onShare: onShare,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack, this.onShare});

  final String title;
  final VoidCallback onBack;
  final ValueChanged<BuildContext>? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _CircleButton(
            key: const Key('preview_back_button'),
            icon: Icons.arrow_back_ios_new,
            onTap: onBack,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: RaroFonts.display,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Builder(
            builder: (buttonContext) {
              return _CircleButton(
                key: const Key('preview_share_button'),
                icon: Icons.ios_share,
                onTap: () {
                  final share = onShare;
                  if (share == null) {
                    _comingSoon(context);
                    return;
                  }
                  share(buttonContext);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderBright),
        ),
        child: Icon(icon, size: 18, color: colors.ink),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.meta});

  final PreviewMetadata meta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElev,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).previewInfoSection,
            style: TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 11,
              letterSpacing: 1.65,
              color: colors.inkFaint,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoColumn(
                value: meta.sizeLabel,
                label: AppLocalizations.of(context).previewSizeLabel,
              ),
              _InfoColumn(
                value: meta.durationLabel,
                label: AppLocalizations.of(context).previewDurationLabel,
              ),
              _InfoColumn(
                value: meta.codecLabel,
                label: AppLocalizations.of(context).previewCodecLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: RaroFonts.mono,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.inkDim)),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isPending,
    required this.onSave,
    required this.onShare,
  });

  final bool isPending;
  final VoidCallback onSave;
  final ValueChanged<BuildContext> onShare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 28 + bottomInset),
      child: Row(
        children: [
          Expanded(
            child: isPending
                ? GestureDetector(
                    key: const Key('preview_save_button'),
                    onTap: onSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.raroRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.save_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).previewSave,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Builder(
                    builder: (buttonContext) {
                      return GestureDetector(
                        onTap: () => onShare(buttonContext),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colors.bgElev,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.borderBright),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.ios_share,
                                size: 18,
                                color: colors.ink,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context).previewShare,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 8),
          _SquareAction(
            icon: Icons.delete_outline,
            color: colors.raroRed,
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(width: 8),
          _SquareAction(
            icon: Icons.info_outline,
            color: colors.ink,
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.bgElev,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderBright),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return SafeArea(
      child: Column(
        children: [
          _Header(
            title: AppLocalizations.of(context).previewVideoTitle,
            onBack: onBack,
          ),
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context).previewVideoNotFound,
                style: TextStyle(color: colors.inkDim),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).comingSoon),
        duration: const Duration(seconds: 1),
      ),
    );
}
