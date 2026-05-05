import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../settings/settings_state.dart';

class GridBackground extends StatelessWidget {
  final GridStyle style;
  const GridBackground({super.key, this.style = GridStyle.dots});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _GridPainter(style)),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final GridStyle style;
  _GridPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case GridStyle.dots:
        _paintDots(canvas, size);
        break;
      case GridStyle.lines:
        _paintLines(canvas, size);
        break;
      case GridStyle.blueprint:
        _paintBlueprint(canvas, size);
        break;
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.lineMid;
    const step = 18.0;
    for (var x = 1.0; x < size.width; x += step) {
      for (var y = 1.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  void _paintLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 0.5;
    const step = 20.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintBlueprint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    final coarse = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.18)
      ..strokeWidth = 0.5;
    const small = 10.0;
    const big = 50.0;
    for (var x = 0.0; x <= size.width; x += small) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fine);
    }
    for (var y = 0.0; y <= size.height; y += small) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fine);
    }
    for (var x = 0.0; x <= size.width; x += big) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), coarse);
    }
    for (var y = 0.0; y <= size.height; y += big) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), coarse);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.style != style;
}
