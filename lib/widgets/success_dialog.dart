// lib/widgets/success_dialog.dart
// Animated success dialog with checkmark animation

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Shows an animated success dialog with a checkmark animation
Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  String? message,
  Duration displayDuration = const Duration(milliseconds: 1500),
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SuccessDialog(
      title: title,
      message: message,
      displayDuration: displayDuration,
    ),
  );
}

class _SuccessDialog extends StatefulWidget {
  final String title;
  final String? message;
  final Duration displayDuration;

  const _SuccessDialog({
    required this.title,
    this.message,
    required this.displayDuration,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Auto-close after display duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated checkmark circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                        child: CustomPaint(
                          painter: _CheckmarkPainter(
                            progress: _checkAnimation.value,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.message!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Checkmark points
    final start = Offset(center.dx - radius * 0.5, center.dy);
    final mid = Offset(center.dx - radius * 0.1, center.dy + radius * 0.4);
    final end = Offset(center.dx + radius * 0.5, center.dy - radius * 0.3);

    final path = Path();
    path.moveTo(start.dx, start.dy);

    if (progress <= 0.5) {
      // First half: draw from start to mid
      final t = progress * 2;
      final x = start.dx + (mid.dx - start.dx) * t;
      final y = start.dy + (mid.dy - start.dy) * t;
      path.lineTo(x, y);
    } else {
      // Second half: complete first line, then draw to end
      path.lineTo(mid.dx, mid.dy);
      final t = (progress - 0.5) * 2;
      final x = mid.dx + (end.dx - mid.dx) * t;
      final y = mid.dy + (end.dy - mid.dy) * t;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
