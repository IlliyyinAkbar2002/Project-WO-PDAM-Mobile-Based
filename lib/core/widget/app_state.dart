import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/config/theme/app_color.dart';
import 'package:project_mobile_pdam/config/theme/assets_path.dart';

abstract class AppState<T extends StatefulWidget> extends State<T> {
  TextTheme get textTheme => Theme.of(context).textTheme;
  AppColor get color => Theme.of(context).extension<AppColor>()!;
  String get assetsPath => Theme.of(context).extension<AssetsPath>()!.path;
}
