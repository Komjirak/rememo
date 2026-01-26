import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Generate icon image matching splash screen design
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(1024, 1024);
  
  // Draw icon matching splash screen design
  _drawSplashIcon(canvas, size);
  
  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save to file
  final file = File('assets/icon.png');
  await file.writeAsBytes(buffer);
  
  print('✅ Icon generated successfully at: ${file.path}');
  print('📱 Run: flutter pub run flutter_launcher_icons');
  exit(0);
}

void _drawSplashIcon(Canvas canvas, Size size) {
  final center = Offset(size.width / 2, size.height / 2);
  
  // Background - black (#000000)
  final bgPaint = Paint()..color = const Color(0xFF000000);
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  
  // Accent Teal color (#2DD4BF)
  const accentTeal = Color(0xFF2DD4BF);
  
  // Icon container size (scaled to 1024x1024)
  // In splash: 224x224, so scale factor = 1024/224 ≈ 4.57
  final iconSize = size.width * 0.875; // ~896px to leave some margin
  final iconRect = Rect.fromCenter(
    center: center,
    width: iconSize,
    height: iconSize,
  );
  
  // Draw rounded rectangle background (22.5% border-radius)
  final borderRadius = iconSize * 0.225;
  final iconRRect = RRect.fromRectAndRadius(iconRect, Radius.circular(borderRadius));
  final iconBgPaint = Paint()..color = const Color(0xFF000000);
  canvas.drawRRect(iconRRect, iconBgPaint);
  
  // Inner border circle (white/10 opacity)
  final innerCircleRadius = iconSize * 0.357; // ~320px (32/224 * 896)
  final innerCirclePaint = Paint()
    ..color = Colors.white.withOpacity(0.1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  canvas.drawCircle(center, innerCircleRadius, innerCirclePaint);
  
  // Corner brackets
  _drawCornerBrackets(canvas, iconRect, accentTeal);
  
  // Center icon (auto_awesome)
  _drawAutoAwesomeIcon(canvas, center, iconSize * 0.25, accentTeal); // ~224px icon size
}

void _drawCornerBrackets(Canvas canvas, Rect iconRect, Color color) {
  final bracketSize = iconRect.width * 0.143; // 32/224
  final borderWidth = iconRect.width * 0.0134; // 3/224
  final cornerRadius = iconRect.width * 0.0179; // 4/224
  final margin = 0.0; // Brackets start at edges
  
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth
    ..strokeCap = StrokeCap.round;
  
  // Glow effect paint
  final glowPaint = Paint()
    ..color = color.withOpacity(0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
  
  // Top Left
  final topLeft = Offset(iconRect.left + margin, iconRect.top + margin);
  canvas.drawLine(
    Offset(topLeft.dx, topLeft.dy + bracketSize),
    topLeft,
    paint,
  );
  canvas.drawLine(
    topLeft,
    Offset(topLeft.dx + bracketSize, topLeft.dy),
    paint,
  );
  // Glow
  canvas.drawLine(
    Offset(topLeft.dx, topLeft.dy + bracketSize),
    topLeft,
    glowPaint,
  );
  canvas.drawLine(
    topLeft,
    Offset(topLeft.dx + bracketSize, topLeft.dy),
    glowPaint,
  );
  
  // Top Right
  final topRight = Offset(iconRect.right - margin, iconRect.top + margin);
  canvas.drawLine(
    Offset(topRight.dx - bracketSize, topRight.dy),
    topRight,
    paint,
  );
  canvas.drawLine(
    topRight,
    Offset(topRight.dx, topRight.dy + bracketSize),
    paint,
  );
  // Glow
  canvas.drawLine(
    Offset(topRight.dx - bracketSize, topRight.dy),
    topRight,
    glowPaint,
  );
  canvas.drawLine(
    topRight,
    Offset(topRight.dx, topRight.dy + bracketSize),
    glowPaint,
  );
  
  // Bottom Left
  final bottomLeft = Offset(iconRect.left + margin, iconRect.bottom - margin);
  canvas.drawLine(
    Offset(bottomLeft.dx, bottomLeft.dy - bracketSize),
    bottomLeft,
    paint,
  );
  canvas.drawLine(
    bottomLeft,
    Offset(bottomLeft.dx + bracketSize, bottomLeft.dy),
    paint,
  );
  // Glow
  canvas.drawLine(
    Offset(bottomLeft.dx, bottomLeft.dy - bracketSize),
    bottomLeft,
    glowPaint,
  );
  canvas.drawLine(
    bottomLeft,
    Offset(bottomLeft.dx + bracketSize, bottomLeft.dy),
    glowPaint,
  );
  
  // Bottom Right
  final bottomRight = Offset(iconRect.right - margin, iconRect.bottom - margin);
  canvas.drawLine(
    Offset(bottomRight.dx - bracketSize, bottomRight.dy),
    bottomRight,
    paint,
  );
  canvas.drawLine(
    bottomRight,
    Offset(bottomRight.dx, bottomRight.dy - bracketSize),
    paint,
  );
  // Glow
  canvas.drawLine(
    Offset(bottomRight.dx - bracketSize, bottomRight.dy),
    bottomRight,
    glowPaint,
  );
  canvas.drawLine(
    bottomRight,
    Offset(bottomRight.dx, bottomRight.dy - bracketSize),
    glowPaint,
  );
}

void _drawAutoAwesomeIcon(Canvas canvas, Offset center, double size, Color color) {
  // Draw glow effect behind icon
  final glowPaint = Paint()
    ..color = color.withOpacity(0.3)
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  canvas.drawCircle(center, size * 0.43, glowPaint);
  
  // Draw auto_awesome icon (sparkle/star shape)
  // This is a simplified representation of Material Icons' auto_awesome
  final iconPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  
  final iconSize = size * 0.5; // Icon takes 50% of the allocated space
  
  // Draw sparkle/star shape
  // Main star (5-pointed)
  _drawStar(canvas, center, iconSize * 0.6, iconSize * 0.3, iconPaint);
  
  // Small sparkles around
  final sparkleCount = 6;
  final sparkleRadius = iconSize * 0.15;
  final sparkleDistance = iconSize * 0.85;
  
  for (int i = 0; i < sparkleCount; i++) {
    final angle = (i * 360 / sparkleCount) * math.pi / 180;
    final sparkleCenter = Offset(
      center.dx + sparkleDistance * math.cos(angle),
      center.dy + sparkleDistance * math.sin(angle),
    );
    _drawSmallSparkle(canvas, sparkleCenter, sparkleRadius, iconPaint);
  }
  
  // Add glow shadow to icon
  final shadowPaint = Paint()
    ..color = color.withOpacity(0.8)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  _drawStar(canvas, center, iconSize * 0.6, iconSize * 0.3, shadowPaint);
}

void _drawStar(Canvas canvas, Offset center, double outerRadius, double innerRadius, Paint paint) {
  final path = Path();
  const points = 5;
  
  for (int i = 0; i < points * 2; i++) {
    final angle = (i * math.pi / points) - math.pi / 2;
    final radius = i.isEven ? outerRadius : innerRadius;
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
}

void _drawSmallSparkle(Canvas canvas, Offset center, double size, Paint paint) {
  // Draw a small 4-pointed star
  final path = Path();
  const points = 4;
  final outerRadius = size;
  final innerRadius = size * 0.4;
  
  for (int i = 0; i < points * 2; i++) {
    final angle = (i * math.pi / points) - math.pi / 4;
    final radius = i.isEven ? outerRadius : innerRadius;
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
}
