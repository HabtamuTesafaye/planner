import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../data/app_exception.dart';
import '../../../data/repositories/auth_repository.dart';

/// "Continue with Google". Opens Google in the browser; the app signs in
/// when Google sends the user back. Errors show as a snackbar.
class GoogleButton extends ConsumerStatefulWidget {
  const GoogleButton({super.key});

  @override
  ConsumerState<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends ConsumerState<GoogleButton> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _busy ? null : _go,
      style: OutlinedButton.styleFrom(
        backgroundColor: context.colors.surface,
        side: BorderSide(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: AppSizes.iconSmall,
            child: CustomPaint(painter: _GoogleMarkPainter()),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              _busy ? 'Opening Google…' : 'Continue with Google',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// The four-colour Google "G" drawn as arcs, so no image asset is needed.
/// Colours are Google's brand values (fixed by their sign-in guidelines,
/// not theme tokens).
class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    double rad(double deg) => deg * math.pi / 180;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    void arc(double from, double to, Color color) => canvas.drawArc(
      rect,
      rad(from),
      rad(to - from),
      false,
      paint..color = color,
    );

    arc(-40, 0, _blue);
    arc(0, 45, _blue);
    arc(45, 135, _green);
    arc(135, 220, _yellow);
    arc(220, 320, _red);
    // The bar of the G.
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        size.height / 2 - stroke / 2,
        size.width / 2,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleMarkPainter old) => false;
}

/// "or" between the email form and Google.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or', style: context.text.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
