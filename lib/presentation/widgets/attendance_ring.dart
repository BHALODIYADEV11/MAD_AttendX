import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

class AttendanceRing extends StatefulWidget {
  final double percentage;
  final double size;
  final int criteria;
  final Widget? child;

  const AttendanceRing({
    super.key,
    required this.percentage,
    this.size = 120,
    this.criteria = 75,
    this.child,
  });

  @override
  State<AttendanceRing> createState() => _AttendanceRingState();
}

class _AttendanceRingState extends State<AttendanceRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AttendanceRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAboveCriteria = widget.percentage >= widget.criteria;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: _animation.value,
              isAboveCriteria: isAboveCriteria,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            child: Center(
              child: widget.child ??
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_animation.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: widget.size * 0.2,
                          fontWeight: FontWeight.bold,
                          color: isAboveCriteria
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isAboveCriteria;
  final bool isDark;

  _RingPainter({
    required this.progress,
    required this.isAboveCriteria,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background ring
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final gradient = isAboveCriteria
        ? const [AppColors.success, Color(0xFF00A882)]
        : const [AppColors.danger, Color(0xFFFF3A62)];

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 2 - math.pi / 2,
        colors: gradient,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow dot at end
    if (progress > 0.01) {
      final dotAngle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(dotAngle);
      final dotY = center.dy + radius * math.sin(dotAngle);

      final glowPaint = Paint()
        ..color = (isAboveCriteria ? AppColors.success : AppColors.danger)
            .withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(dotX, dotY), 6, glowPaint);

      final dotPaint = Paint()
        ..color = isAboveCriteria ? AppColors.success : AppColors.danger;

      canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
