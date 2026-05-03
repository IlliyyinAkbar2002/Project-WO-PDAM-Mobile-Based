part of '../landing_page.dart';

/// Attendance card berbasis Figma:
/// background kuning lembut + ikon putih, tombol "Clock In" pill biru,
/// progress bar gradient dengan thumb, dan label jam kerja.
///
/// Nilai di kartu ini saat ini placeholder mengikuti mockup; di masa depan
/// dapat dihubungkan ke sumber data attendance.
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  static const String _checkIn = '07:30';
  static const String _checkOut = '16:30';
  static const String _workedLabel = '5h 34m worked';
  static const String _remainingLabel = '3h 26m remaining';
  static const double _progress = 0.62;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    const navy = Color(0xFF0B2A6B);
    const cardBg = Color(0xFFFFF4B8);
    const borderColor = Color(0x99FFF085); // rgba(255,240,133,0.6)
    const subText = Color(0xCC0B2A6B); // navy 0.8
    const labelText = Color(0xB30B2A6B); // navy 0.7
    const trackColor = Color(0xB3FFFFFF); // white 0.7
    const fillStart = Color(0xFF2E7BFF);
    const fillEnd = Color(0xFF0B2A6B);
    const buttonColor = Color(0xFF2E7BFF);
    const iconBg = Color(0xB3FFFFFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(16),
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
                  Icons.access_time_rounded,
                  color: navy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTENDANCE',
                      style: textTheme.labelSmall?.copyWith(
                        color: navy.withOpacity(0.6),
                        fontSize: 11,
                        letterSpacing: 1.54,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Today's Shift",
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
              _ClockInPillButton(
                color: buttonColor,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in $_checkIn',
                style: textTheme.bodySmall?.copyWith(
                  color: subText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              Text(
                'Check-out $_checkOut',
                style: textTheme.bodySmall?.copyWith(
                  color: subText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _AttendanceProgressBar(
            progress: _progress,
            trackColor: trackColor,
            fillGradient: LinearGradient(
              colors: [fillStart, fillEnd],
            ),
            thumbBorderColor: buttonColor,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _workedLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: labelText,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              Text(
                _remainingLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: labelText,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockInPillButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ClockInPillButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Clock In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceProgressBar extends StatelessWidget {
  final double progress;
  final Color trackColor;
  final Gradient fillGradient;
  final Color thumbBorderColor;

  const _AttendanceProgressBar({
    required this.progress,
    required this.trackColor,
    required this.fillGradient,
    required this.thumbBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fillWidth = (width * progress).clamp(0.0, width);
        const trackHeight = 10.0;
        const thumbSize = 14.0;

        return SizedBox(
          height: thumbSize,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: trackHeight,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: fillWidth,
                height: trackHeight,
                decoration: BoxDecoration(
                  gradient: fillGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: (fillWidth - thumbSize / 2).clamp(0.0, width - thumbSize),
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: thumbBorderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
