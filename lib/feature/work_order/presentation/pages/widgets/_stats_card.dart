part of '../landing/landing_page.dart';

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  String _extractArea(String? locationText) {
    if (locationText == null || locationText.trim().isEmpty) return '';
    final cleaned = locationText.trim();
    final regExp = RegExp(r'Area\s+[A-Za-z0-9]+', caseSensitive: false);
    final match = regExp.firstMatch(cleaned);
    if (match != null) {
      final matchedStr = match.group(0)!;
      final parts = matchedStr.split(RegExp(r'\s+'));
      if (parts.length == 2) {
        return '${parts[0][0].toUpperCase()}${parts[0].substring(1).toLowerCase()} ${parts[1].toUpperCase()}';
      }
      return matchedStr;
    }
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length > 2) {
      return '${words[0]} ${words[1]}';
    }
    return cleaned;
  }

  int _priorityValue(String? priority) {
    switch (priority?.trim().toLowerCase()) {
      case 'darurat':
        return 4;
      case 'tinggi':
        return 3;
      case 'sedang':
        return 2;
      case 'rendah':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appColor = Theme.of(context).extension<AppColor>();

    const navy = Color(0xFF0B2A6B);
    const muted = Color(0xFF90A1B9);
    const iconBg = Color(0xFFEAF1FF);
    const iconColor = Color(0xFF2E7BFF);
    const liveBg = Color(0xFFFFF4B8);
    const successText = Color(0xFF009966);
    const trendStart = Color(0xFF2E7BFF);
    const trendEnd = Color(0xFF0B2A6B);
    const borderColor = Color(0xFFF1F5F9);

    final String role = AuthStorage.getJabatanKodeSync() ?? '';
    final String cardTitle;
    final String focusLabel;

    if (role == 'SPV') {
      cardTitle = 'Operational Oversight';
      focusLabel = 'Active Sectors';
    } else if (role == 'SENIOR_STAFF') {
      cardTitle = 'Field Operations PIC';
      focusLabel = "Today's Focus";
    } else {
      cardTitle = 'Field Operations Staff';
      focusLabel = "Today's Focus";
    }

    return BlocBuilder<WorkOrderBloc, WorkOrderState>(
      buildWhen: (previous, current) =>
          current is WorkOrderLoaded || current is WorkOrderLoading,
      builder: (context, state) {
        String activeOrdersCount = '--';
        String focusArea = '--';
        String weeklyTrendText = '0% this week';
        Color trendColor = muted;
        List<double> dailyCounts = List.filled(7, 0.0);

        if (state is WorkOrderLoaded) {
          // 1. Calculate active orders in-memory
          final activeOrders = state.workOrders
              .where((wo) => wo.statusId != WorkOrderStatusId.selesai)
              .toList();
          activeOrdersCount = activeOrders.length.toString();

          // 2. Resolve focus area
          if (role == 'SPV') {
            final areas = activeOrders
                .map(
                  (wo) => _extractArea(
                    wo.lokasiText ?? wo.assignment?.location?.nama,
                  ),
                )
                .where((area) => area.isNotEmpty)
                .toSet()
                .toList();

            if (areas.isEmpty) {
              focusArea = 'No Sectors';
            } else if (areas.length == 1) {
              focusArea = areas.first;
            } else if (areas.length <= 2) {
              focusArea = areas.join(', ');
            } else {
              focusArea = '${areas.length} Sectors';
            }
          } else {
            if (activeOrders.isNotEmpty) {
              final sortedWos = List<dynamic>.from(activeOrders);
              sortedWos.sort((a, b) {
                final pA = _priorityValue(a.prioritas);
                final pB = _priorityValue(b.prioritas);
                return pB.compareTo(pA);
              });
              final highestWo = sortedWos.first;
              final extracted = _extractArea(
                highestWo.lokasiText ?? highestWo.assignment?.location?.nama,
              );
              focusArea = extracted.isNotEmpty ? extracted : 'General';
            } else {
              focusArea = 'No Focus';
            }
          }

          // 3. Compute Weekly Trend Percentage and Daily Counts
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final dailyPeriods = List.generate(7, (i) {
            return todayStart.subtract(Duration(days: 6 - i));
          });

          final thisWeekStart = todayStart.subtract(const Duration(days: 6));
          final nextDay = todayStart.add(const Duration(days: 1));
          final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
          final lastWeekEnd = thisWeekStart;

          int thisWeekCount = 0;
          int lastWeekCount = 0;

          for (final wo in state.workOrders) {
            final created = wo.createdAt?.toLocal();
            if (created == null) continue;

            if (!created.isBefore(thisWeekStart) && created.isBefore(nextDay)) {
              thisWeekCount++;
            } else if (!created.isBefore(lastWeekStart) &&
                created.isBefore(lastWeekEnd)) {
              lastWeekCount++;
            }

            for (int i = 0; i < 7; i++) {
              final dayStart = dailyPeriods[i];
              final dayEnd = dayStart.add(const Duration(days: 1));
              if (!created.isBefore(dayStart) && created.isBefore(dayEnd)) {
                dailyCounts[i] += 1.0;
                break;
              }
            }
          }

          final double percent = lastWeekCount == 0
              ? (thisWeekCount * 100.0)
              : ((thisWeekCount - lastWeekCount) / lastWeekCount) * 100;

          if (percent > 0) {
            trendColor = successText;
            weeklyTrendText = '+${percent.toStringAsFixed(0)}% this week';
          } else if (percent < 0) {
            trendColor = appColor?.danger ?? const Color(0xFFDC2626);
            weeklyTrendText = '${percent.toStringAsFixed(0)}% this week';
          } else {
            trendColor = muted;
            weeklyTrendText = '0% this week';
          }
        } else if (state is WorkOrderLoading) {
          activeOrdersCount = '...';
          focusArea = 'Loading...';
          weeklyTrendText = 'Loading...';
          trendColor = muted;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.6),
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
                          cardTitle,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatBlock(
                            label: 'Active Orders',
                            value: activeOrdersCount,
                          ),
                          const SizedBox(height: 8),
                          _StatBlock(label: focusLabel, value: focusArea),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            weeklyTrendText,
                            style: textTheme.labelSmall?.copyWith(
                              color: trendColor,
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
                                dataPoints: dailyCounts,
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
      },
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

class _TrendLinePainter extends CustomPainter {
  final Color startColor;
  final Color endColor;
  final List<double>? dataPoints;

  _TrendLinePainter({
    required this.startColor,
    required this.endColor,
    this.dataPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pts = dataPoints;
    if (pts == null || pts.isEmpty) return;

    final double maxVal = pts.reduce((a, b) => a > b ? a : b);
    final double minVal = pts.reduce((a, b) => a < b ? a : b);
    final double range = maxVal - minVal;

    final points = <Offset>[];
    final double stepX = size.width / (pts.length - 1);

    for (int i = 0; i < pts.length; i++) {
      final double x = i * stepX;
      double y;
      if (range == 0) {
        y = size.height * 0.5;
      } else {
        final normalized = (pts[i] - minVal) / range;
        y = size.height * 0.85 - (normalized * size.height * 0.7);
      }
      points.add(Offset(x, y));
    }

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
        colors: [
          endColor.withValues(alpha: 0.15),
          endColor.withValues(alpha: 0.0),
        ],
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
      oldDelegate.startColor != startColor ||
      oldDelegate.endColor != endColor ||
      !_listEquals(oldDelegate.dataPoints, dataPoints);

  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
