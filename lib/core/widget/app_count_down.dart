import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state.dart';

class AppCountDown extends StatefulWidget {
  final Duration duration;
  const AppCountDown({super.key, required this.duration});

  @override
  State<AppCountDown> createState() => _AppCountDownState();
}

class _AppCountDownState extends AppState<AppCountDown>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  String get counterText {
    final Duration count = controller.duration! * controller.value;
    return count.inSeconds.toString();
  }

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    controller.reverse();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Colors.primaries[500],
                value: controller.value,
                strokeWidth: 2,
              ),
            ),
            Text(
              counterText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.primaries[500],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
