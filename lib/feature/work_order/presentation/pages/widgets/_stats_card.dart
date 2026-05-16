part of '../landing/landing_page.dart';

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    const navy = Color(0xFF0B2A6B);
    const muted = Color(0xFF90A1B9);
    const iconBg = Color(0xFFEAF1FF);
    const iconColor = Color(0xFF2E7BFF);
    const liveBg = Color(0xFFFFF4B8);
    const successText = Color(0xFF009966);
    const trendStart = Color(0xFF2E7BFF);
    const trendEnd = Color(0xFF0B2A6B);
    const borderColor = Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.6),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORK ORDERS',
                      style: textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontSize: 11,
                        letterSpacing: 1.54,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Field Operations',
                      style: textTheme.titleLarge?.copyWith(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: liveBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Live',
                  style: textTheme.labelSmall?.copyWith(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatBlock(label: 'Active Orders', value: '12'),
                      SizedBox(height: 8),
                      _StatBlock(label: "Today's Focus", value: 'Area A'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+8% this week',
                        style: textTheme.labelSmall?.copyWith(
                          color: successText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 40,
                        width: 120,
                        child: CustomPaint(
                          painter: _TrendLinePainter(
                            startColor: trendStart,
                            endColor: trendEnd,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: const Color(0xFF90A1B9),
            fontSize: 11,
            letterSpacing: 0.55,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: const Color(0xFF0B2A6B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Painter sederhana untuk trendline statistik. Bukan grafik real-time;
/// hanya representasi visual seperti pada mockup Figma.
class _TrendLinePainter extends CustomPainter {
  final Color startColor;
  final Color endColor;

  _TrendLinePainter({required this.startColor, required this.endColor});

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.18, size.height * 0.55),
      Offset(size.width * 0.32, size.height * 0.65),
      Offset(size.width * 0.48, size.height * 0.35),
      Offset(size.width * 0.62, size.height * 0.50),
      Offset(size.width * 0.78, size.height * 0.20),
      Offset(size.width, size.height * 0.10),
    ];

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [endColor.withOpacity(0.15), endColor.withOpacity(0.0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [startColor, endColor],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.startColor != startColor || oldDelegate.endColor != endColor;
}
