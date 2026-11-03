import 'package:flutter/material.dart';

class EmbroideryMachineArt extends StatelessWidget {
  final double width;
  final double height;

  const EmbroideryMachineArt({
    super.key,
    this.width = 130,
    this.height = 95,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _EmbroideryMachinePainter(),
      ),
    );
  }
}

class _EmbroideryMachinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final lightStroke = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = const Color(0xFFEFF6FF).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final darkFill = Paint()
      ..color = const Color(0xFFDBEAFE).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // 1. Isometric Table Bed / Base
    final bedPath = Path()
      ..moveTo(w * 0.15, h * 0.65)
      ..lineTo(w * 0.65, h * 0.50)
      ..lineTo(w * 0.90, h * 0.68)
      ..lineTo(w * 0.40, h * 0.85)
      ..close();

    canvas.drawPath(bedPath, fillPaint);
    canvas.drawPath(bedPath, strokePaint);

    // Bed thickness (front & left edges)
    final bedThickness = Path()
      ..moveTo(w * 0.15, h * 0.65)
      ..lineTo(w * 0.15, h * 0.72)
      ..lineTo(w * 0.40, h * 0.92)
      ..lineTo(w * 0.90, h * 0.75)
      ..lineTo(w * 0.90, h * 0.68)
      ..lineTo(w * 0.40, h * 0.85)
      ..close();

    canvas.drawPath(bedThickness, darkFill);
    canvas.drawPath(bedThickness, strokePaint);

    // Legs
    canvas.drawLine(Offset(w * 0.18, h * 0.72), Offset(w * 0.18, h * 0.95), strokePaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.92), Offset(w * 0.40, h * 0.99), strokePaint);
    canvas.drawLine(Offset(w * 0.87, h * 0.75), Offset(w * 0.87, h * 0.96), strokePaint);

    // 2. Upright Machine Column (Right Side)
    final colPath = Path()
      ..moveTo(w * 0.62, h * 0.51)
      ..lineTo(w * 0.62, h * 0.22)
      ..lineTo(w * 0.78, h * 0.15)
      ..lineTo(w * 0.78, h * 0.55)
      ..close();

    canvas.drawPath(colPath, fillPaint);
    canvas.drawPath(colPath, strokePaint);

    // 3. Horizontal Sewing Arm (Extending left over bed)
    final armPath = Path()
      ..moveTo(w * 0.75, h * 0.22)
      ..lineTo(w * 0.30, h * 0.35)
      ..lineTo(w * 0.30, h * 0.45)
      ..lineTo(w * 0.65, h * 0.38)
      ..close();

    canvas.drawPath(armPath, fillPaint);
    canvas.drawPath(armPath, strokePaint);

    // 4. Multi-Needle Head Assembly
    final headPath = Path()
      ..moveTo(w * 0.25, h * 0.34)
      ..lineTo(w * 0.38, h * 0.30)
      ..lineTo(w * 0.38, h * 0.56)
      ..lineTo(w * 0.25, h * 0.60)
      ..close();

    canvas.drawPath(headPath, darkFill);
    canvas.drawPath(headPath, strokePaint);

    // Needles & Presser Foot
    for (int i = 0; i < 4; i++) {
      final nx = w * 0.28 + (i * 2.5);
      canvas.drawLine(Offset(nx, h * 0.56), Offset(nx, h * 0.68), strokePaint);
    }

    // Needle guide / thread levers
    canvas.drawLine(Offset(w * 0.24, h * 0.40), Offset(w * 0.39, h * 0.36), lightStroke);
    canvas.drawLine(Offset(w * 0.24, h * 0.48), Offset(w * 0.39, h * 0.44), lightStroke);

    // 5. Thread Spool Rack on Top with Cones
    final rackY = h * 0.12;
    canvas.drawLine(Offset(w * 0.40, rackY), Offset(w * 0.75, rackY * 0.8), strokePaint);
    canvas.drawLine(Offset(w * 0.57, rackY), Offset(w * 0.57, h * 0.25), strokePaint);

    // 5 Thread cones
    for (int i = 0; i < 5; i++) {
      final cx = w * 0.42 + (i * 7.5);
      final cy = rackY + (i * -1.2);

      final cone = Path()
        ..moveTo(cx - 2.5, cy + 8)
        ..lineTo(cx + 2.5, cy + 8)
        ..lineTo(cx + 1.5, cy - 2)
        ..lineTo(cx - 1.5, cy - 2)
        ..close();

      canvas.drawPath(cone, fillPaint);
      canvas.drawPath(cone, strokePaint);

      // Thread line down to arm
      canvas.drawLine(Offset(cx, cy - 2), Offset(w * 0.32 + (i * 2.0), h * 0.35), lightStroke);
    }

    // Embroidery Frame / Hoop on Bed
    final hoopPath = Path()
      ..moveTo(w * 0.32, h * 0.63)
      ..lineTo(w * 0.55, h * 0.56)
      ..lineTo(w * 0.62, h * 0.65)
      ..lineTo(w * 0.39, h * 0.72)
      ..close();

    canvas.drawPath(hoopPath, lightStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
