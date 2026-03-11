// lib/shared/widgets/progress_ring.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress, // 0.0 → 1.0
    required this.label, // e.g. "2 of 3 promises kept"
    this.size = 180,
    this.strokeWidth = 12,
  });

  final double progress;
  final String label;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter:
                _RingPainter(progress: progress, strokeWidth: strokeWidth),
          ),
          // Center label
          Padding(
            padding: EdgeInsets.all(strokeWidth * 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: KYVText.caption(context).copyWith(
                color: KYVColors.slate,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFD6EAF8) // KYVColors.light
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at top
      2 * math.pi * progress, // sweep clockwise
      false,
      Paint()
        ..color = progress >= 1
            ? const Color(0xFF1ABC9C) // KYVColors.teal — all done
            : const Color(0xFF2E86C1) // KYVColors.sky — in progress
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
