import 'dart:ui';

import 'package:project_mobile_pdam/config/theme/app_color.dart';

class ColorData {
  static AppColor get defaultColor => AppColor(
    primary: {
      100: const Color(0xffd5dbeb),
      200: const Color(0xffbaeafc),
      300: const Color(0xff3abfef),
      400: const Color(0xff2a83c6),
      500: const Color(0xff2d499b),
      600: const Color(0xff243a7c),
      700: const Color(0xff1b2c5d),
      800: const Color(0xff121d3e),
      900: const Color(0xff090f1f),
    },
    foreground: {
      100: const Color(0xFFD6D6D6),
      200: const Color(0xFFADADAD),
      300: const Color(0xFF848484),
      400: const Color(0xFF5B5B5B),
      500: const Color(0xFF323232),
      600: const Color(0xFF282828),
      700: const Color(0xFF1E1E1E),
      800: const Color(0xFF141414),
      900: const Color(0xFF0A0A0A),
    },
    background: {
      100: const Color(0xFFFEFEFE),
      200: const Color(0xFFFDFDFD),
      300: const Color(0xFFFCFCFC),
      400: const Color(0xFFFBFBFB),
      500: const Color(0xFFF9F9F9),
      600: const Color(0xFFF7F6F6),
      700: const Color(0xFFC8C8C8),
      800: const Color(0xFF969696),
      900: const Color(0xFF969696),
    },
    status: {
      1: const Color(0xff2a83c6),
      2: const Color(0xffd5ef77),
      3: const Color(0xffff574d),
      4: const Color(0xffe92215),
      5: const Color(0xFFAB8DFF),
      6: const Color(0xff2d499b),
      7: const Color(0xFF2AC6B1),
      8: const Color(0xFF77EDFF),
      12: const Color(0xFFE5EDFF),
      13: const Color(0xFFE4F7EC),
      16: const Color(0xFFFFF2C2),
      17: const Color(0xFFFFE0DA),
    },
    success: const Color(0xff048746),
    warning: const Color(0xffffc700),
    control: const Color(0xFFAB8DFF),
    danger: const Color(0xffff3d00),
  );
}
