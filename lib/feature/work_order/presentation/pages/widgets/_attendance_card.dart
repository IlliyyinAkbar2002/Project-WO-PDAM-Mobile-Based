part of '../landing/landing_page.dart';

/// Attendance card berbasis Figma:
/// background kuning lembut + ikon putih, tombol action pill,
/// progress bar gradient dengan thumb, dan label jam kerja.
///
/// Nilai di kartu ini dirancang interaktif secara lokal untuk tujuan demo,
/// menampilkan animasi pulsing ketika Clock In aktif dan simulasi waktu yang berjalan.
class _AttendanceCard extends StatefulWidget {
  const _AttendanceCard();

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard>
    with SingleTickerProviderStateMixin {
  bool _isClockedIn = false;
  bool _isClockedOut = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  Duration _workedDuration = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseController;

  static const Duration _totalShiftDuration = Duration(hours: 9);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _pulseController.repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Simulasi cepat untuk demo: 1 detik di dunia nyata = 5 menit durasi kerja
        _workedDuration += const Duration(minutes: 5);

        if (_workedDuration >= _totalShiftDuration) {
          _workedDuration = _totalShiftDuration;
          _clockOut();
        }
      });
    });
  }

  void _clockIn() {
    setState(() {
      _isClockedIn = true;
      _isClockedOut = false;
      _checkInTime = DateTime.now();
      _checkOutTime = null;
      _workedDuration = Duration.zero;
    });
    _startTimer();
  }

  void _clockOut() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isClockedIn = false;
      _isClockedOut = true;
      if (_checkInTime != null) {
        _checkOutTime = _checkInTime!.add(_workedDuration);
      } else {
        _checkOutTime = DateTime.now();
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isClockedIn = false;
      _isClockedOut = false;
      _checkInTime = null;
      _checkOutTime = null;
      _workedDuration = Duration.zero;
    });
  }

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
    const buttonBlue = Color(0xFF2E7BFF);
    const buttonRed = Color(0xFFE63946);
    const buttonGrey = Color(0xFF64748B);
    const iconBg = Color(0xB3FFFFFF);

    final remainingDuration = _totalShiftDuration - _workedDuration;
    final progress = (_workedDuration.inMinutes / _totalShiftDuration.inMinutes)
        .clamp(0.0, 1.0);

    final checkInStr = _checkInTime != null
        ? "${_checkInTime!.hour.toString().padLeft(2, '0')}:${_checkInTime!.minute.toString().padLeft(2, '0')}"
        : '--:--';

    final checkOutStr = _checkOutTime != null
        ? "${_checkOutTime!.hour.toString().padLeft(2, '0')}:${_checkOutTime!.minute.toString().padLeft(2, '0')}"
        : '--:--';

    final workedLabel =
        "${_workedDuration.inHours}h ${_workedDuration.inMinutes % 60}m worked";
    final remainingLabel =
        "${remainingDuration.inHours}h ${remainingDuration.inMinutes % 60}m remaining";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                        color: navy.withValues(alpha: 0.6),
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
              if (_isClockedIn)
                _AttendanceActionButton(
                  color: buttonRed,
                  text: 'Clock Out',
                  onTap: _clockOut,
                )
              else if (_isClockedOut)
                _AttendanceActionButton(
                  color: buttonGrey,
                  text: 'Reset',
                  onTap: _reset,
                )
              else
                _AttendanceActionButton(
                  color: buttonBlue,
                  text: 'Clock In',
                  onTap: _clockIn,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in $checkInStr',
                style: textTheme.bodySmall?.copyWith(
                  color: subText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              Text(
                'Check-out $checkOutStr',
                style: textTheme.bodySmall?.copyWith(
                  color: subText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AttendanceProgressBar(
            progress: progress,
            trackColor: trackColor,
            fillGradient: const LinearGradient(colors: [fillStart, fillEnd]),
            thumbBorderColor: fillStart,
            pulseController: _isClockedIn ? _pulseController : null,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                workedLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: labelText,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              Text(
                remainingLabel,
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

class _AttendanceActionButton extends StatelessWidget {
  final Color color;
  final String text;
  final VoidCallback onTap;

  const _AttendanceActionButton({
    required this.color,
    required this.text,
    required this.onTap,
  });

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
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
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
  final AnimationController? pulseController;

  const _AttendanceProgressBar({
    required this.progress,
    required this.trackColor,
    required this.fillGradient,
    required this.thumbBorderColor,
    this.pulseController,
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
              // Track
              Container(
                height: trackHeight,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Fill Progress
              Container(
                width: fillWidth,
                height: trackHeight,
                decoration: BoxDecoration(
                  gradient: fillGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Pulse Glow Animation (Ripple Effect)
              if (pulseController != null && progress > 0.0 && progress < 1.0)
                AnimatedBuilder(
                  animation: pulseController!,
                  builder: (context, child) {
                    final pulseVal = pulseController!.value;
                    return Positioned(
                      left: (fillWidth - thumbSize / 2).clamp(
                        0.0,
                        width - thumbSize,
                      ),
                      child: Transform.scale(
                        scale: 1.0 + (pulseVal * 1.2), // Scale up to 2.2x size
                        child: Opacity(
                          opacity: (1.0 - pulseVal).clamp(0.0, 1.0), // Fade out
                          child: Container(
                            width: thumbSize,
                            height: thumbSize,
                            decoration: BoxDecoration(
                              color: thumbBorderColor.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Slider Thumb
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
                        color: Colors.black.withValues(alpha: 0.1),
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
