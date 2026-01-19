import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Generate icon image
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(1024, 1024);
  
  // Draw icon
  _drawIcon(canvas, size);
  
  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save to file
  final file = File('assets/icon.png');
  await file.writeAsBytes(buffer);
  
  print('Icon generated successfully at: ${file.path}');
  exit(0);
}

void _drawIcon(Canvas canvas, Size size) {
  final center = Offset(size.width / 2, size.height / 2);
  
  // Background
  final bgPaint = Paint()..color = const Color(0xFF0A0A0B);
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  
  final tealColor = const Color(0xFF2DD4BF);
  
  // Corner brackets
  _drawCornerBrackets(canvas, size, tealColor);
  
  // Hexagon
  _drawHexagon(canvas, center, size.width * 0.35, tealColor);
  
  // Dashed circle
  _drawDashedCircle(canvas, center, size.width * 0.25, tealColor);
  
  // Dots in circle
  _drawDotsCircle(canvas, center, size.width * 0.18, tealColor);
  
  // Center square
  final squareSize = size.width * 0.08;
  final squareRect = Rect.fromCenter(
    center: center,
    width: squareSize,
    height: squareSize,
  );
  final squarePaint = Paint()
    ..color = tealColor
    ..style = PaintingStyle.fill;
  
  final squareRRect = RRect.fromRectAndRadius(
    squareRect,
    Radius.circular(squareSize * 0.15),
  );
  canvas.drawRRect(squareRRect, squarePaint);
  
  // Glow effect
  final glowPaint = Paint()
    ..color = tealColor.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
  canvas.drawRRect(squareRRect, glowPaint);
}

void _drawCornerBrackets(Canvas canvas, Size size, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round;
  
  final bracketSize = size.width * 0.12;
  final margin = size.width * 0.08;
  
  // Top-left
  canvas.drawLine(
    Offset(margin, margin + bracketSize),
    Offset(margin, margin),
    paint,
  );
  canvas.drawLine(
    Offset(margin, margin),
    Offset(margin + bracketSize, margin),
    paint,
  );
  
  // Top-right
  canvas.drawLine(
    Offset(size.width - margin - bracketSize, margin),
    Offset(size.width - margin, margin),
    paint,
  );
  canvas.drawLine(
    Offset(size.width - margin, margin),
    Offset(size.width - margin, margin + bracketSize),
    paint,
  );
  
  // Bottom-left
  canvas.drawLine(
    Offset(margin, size.height - margin - bracketSize),
    Offset(margin, size.height - margin),
    paint,
  );
  canvas.drawLine(
    Offset(margin, size.height - margin),
    Offset(margin + bracketSize, size.height - margin),
    paint,
  );
  
  // Bottom-right
  canvas.drawLine(
    Offset(size.width - margin - bracketSize, size.height - margin),
    Offset(size.width - margin, size.height - margin),
    paint,
  );
  canvas.drawLine(
    Offset(size.width - margin, size.height - margin),
    Offset(size.width - margin, size.height - margin - bracketSize),
    paint,
  );
}

void _drawHexagon(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  
  final path = Path();
  for (int i = 0; i < 6; i++) {
    final angle = (i * 60 - 90) * math.pi / 180;
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  
  canvas.drawPath(path, paint);
  
  // Glow
  final glowPaint = Paint()
    ..color = color.withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  canvas.drawPath(path, glowPaint);
}

void _drawDashedCircle(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()
    ..color = color.withOpacity(0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  
  const dashCount = 40;
  const dashLength = 10.0;
  const gapLength = 10.0;
  
  for (int i = 0; i < dashCount; i++) {
    final angle1 = (i * (360 / dashCount)) * math.pi / 180;
    final angle2 = angle1 + (dashLength / (2 * math.pi * radius));
    
    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      angle1,
      angle2 - angle1,
    );
    
    canvas.drawPath(path, paint);
  }
}

void _drawDotsCircle(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()
    ..color = color.withOpacity(0.8)
    ..style = PaintingStyle.fill;
  
  const dotCount = 24;
  const dotRadius = 6.0;
  
  for (int i = 0; i < dotCount; i++) {
    final angle = (i * 360 / dotCount) * math.pi / 180;
    final x = center.dx + radius * math.cos(angle);
    final y = center.dy + radius * math.sin(angle);
    
    canvas.drawCircle(Offset(x, y), dotRadius, paint);
  }
}
