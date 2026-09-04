import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/preview/domain/preview_clip_details.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class PreviewDetailsSheet extends StatelessWidget {
  const PreviewDetailsSheet({super.key, required this.details});

  final PreviewClipDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<RaroColors>()!;
    final unavailable = l10n.previewDetailsUnavailable;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderBright,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.previewDetailsTitle,
                style: const TextStyle(
                  fontFamily: RaroFonts.display,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _DetailsRow(label: l10n.previewDetailsName, value: details.name),
              _DetailsRow(
                label: l10n.previewDetailsDuration,
                value: details.durationLabel,
              ),
              _DetailsRow(
                label: l10n.previewDetailsRecordedAt,
                value: details.recordedAtLabel,
              ),
              _DetailsRow(
                label: l10n.previewDetailsResolution,
                value: details.resolutionLabel ?? unavailable,
              ),
              _DetailsRow(
                label: l10n.previewDetailsFps,
                value: details.fpsLabel ?? unavailable,
              ),
              _DetailsRow(
                label: l10n.previewDetailsLens,
                value: details.lensLabel ?? unavailable,
              ),
              _DetailsRow(
                label: l10n.previewDetailsSize,
                value: details.sizeLabel ?? unavailable,
              ),
              _DetailsRow(
                label: l10n.previewDetailsReplay,
                value: details.isReplay
                    ? l10n.previewDetailsReplayYes
                    : l10n.previewDetailsReplayNo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: RaroFonts.mono,
                fontSize: 12,
                color: colors.inkDim,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: RaroFonts.mono,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
