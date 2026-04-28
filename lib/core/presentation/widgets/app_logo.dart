import 'package:flutter/material.dart';
import 'package:hisabet/core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppColors.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: logoColor,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: logoColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stylized Geometric "H" + Ledger
              SizedBox(
                width: size * 0.45,
                height: size * 0.45,
                child: CustomPaint(
                  painter: _LogoPainter(color: Colors.white),
                ),
              ),
              // Gold Accent Dot (The "Precision" Dot)
              Positioned(
                top: size * 0.28,
                right: size * 0.28,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.12,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: logoColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'HisabET',
            style: TextStyle(
              color: logoColor,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;

  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Draw two minimalist vertical bars
    // Left bar (full)
    canvas.drawLine(Offset(w * 0.15, h * 0.1), Offset(w * 0.15, h * 0.9), paint);
    // Right bar (partial, more elegant)
    canvas.drawLine(Offset(w * 0.85, h * 0.3), Offset(w * 0.85, h * 0.9), paint);

    // Draw the bridge (slanted upward for growth)
    final bridgePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(Offset(w * 0.15, h * 0.6), Offset(w * 0.85, h * 0.45), bridgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

