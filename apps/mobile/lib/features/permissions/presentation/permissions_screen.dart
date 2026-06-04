import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/core/theme/raro_theme.dart';
import 'package:raro_mobile/features/onboarding/application/onboarding_progress_provider.dart';
import 'package:raro_mobile/features/permissions/application/permission_status_provider.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key, required this.onGranted});

  final VoidCallback onGranted;

  Future<void> _continue(WidgetRef ref) async {
    final status = await ref
        .read(permissionControllerProvider.notifier)
        .request();
    if (status == CamMicStatus.granted) {
      await ref.read(onboardingProgressProvider.notifier).markCompleted();
      onGranted();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Scaffold(
      backgroundColor: colors.bgDeep,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 70, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      RaroGradients.rainbow.createShader(bounds),
                  child: const Text(
                    'PASSO 1 DE 1',
                    style: TextStyle(
                      fontFamily: RaroFonts.mono,
                      fontSize: 10,
                      letterSpacing: 1.8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Permissões essenciais',
                  style: TextStyle(
                    fontFamily: RaroFonts.display,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O RARO precisa de acesso para funcionar plenamente. '
                  'Você pode revogar a qualquer momento.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: colors.inkDim,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                children: [
                  _PermissionCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Câmera',
                    description:
                        'Necessário para gravar vídeo em 4K com lentes '
                        '0.5x e 1x.',
                  ),
                  SizedBox(height: 10),
                  _PermissionCard(
                    icon: Icons.mic_none_rounded,
                    title: 'Microfone',
                    description:
                        'Para áudio do vídeo e para escutar o comando “Raro”.',
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
            child: GestureDetector(
              onTap: () => _continue(ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: RaroGradients.rainbow,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<RaroColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElev,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.bgDeep,
              border: Border.all(color: colors.borderBright),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: colors.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: colors.inkDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
