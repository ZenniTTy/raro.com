import 'package:flutter/material.dart';
import 'package:raro_mobile/core/theme/raro_fonts.dart';
import 'package:raro_mobile/core/theme/raro_gradients.dart';
import 'package:raro_mobile/l10n/app_localizations.dart';

class PrerollConfirmation extends StatefulWidget {
  const PrerollConfirmation({super.key, required this.seconds});

  final int seconds;

  @override
  State<PrerollConfirmation> createState() => _PrerollConfirmationState();
}

class _PrerollConfirmationState extends State<PrerollConfirmation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  double _opacityFor(double t) {
    const fadeIn = 0.12;
    const fadeOut = 0.78;
    if (t < fadeIn) return t / fadeIn;
    if (t > fadeOut) return (1 - t) / (1 - fadeOut);
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.viewPaddingOf(context).bottom + 124,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _fade.drive(_OpacityTween(opacityFor: _opacityFor)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: RaroAccents.teal.withValues(alpha: 0.6),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.replay, size: 14, color: RaroAccents.teal),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).cameraPrerollIncluded(widget.seconds),
                    style: const TextStyle(
                      fontFamily: RaroFonts.mono,
                      fontSize: 11,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpacityTween extends Animatable<double> {
  _OpacityTween({required this.opacityFor});

  final double Function(double) opacityFor;

  @override
  double transform(double t) => opacityFor(t).clamp(0.0, 1.0);
}
