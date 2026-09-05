import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/legal/domain/legal_document.dart';
import 'package:raro_mobile/features/legal/domain/legal_markdown.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.document,
    required this.onBack,
  });

  final LegalDocument document;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final title = document == LegalDocument.terms
        ? l10n.termsOfUse
        : l10n.privacyPolicy;

    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: title, onBack: onBack),
            Container(
              height: 1,
              decoration: const BoxDecoration(gradient: RaroGradients.rainbow),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: rootBundle.loadString(document.assetPath(locale)),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      SelectableText(
                        l10n.legalCanonicalHint(document.canonicalUrl(locale)),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: colors.inkDim,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        legalMarkdownToPlain(snapshot.data!),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: colors.ink,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('legal_back_button'),
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderBright),
              ),
              child: Icon(Icons.chevron_left, color: colors.ink, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: RaroFonts.display,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
