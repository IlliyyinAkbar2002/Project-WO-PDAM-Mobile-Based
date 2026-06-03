import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/utils/app_snackbar.dart';
import 'package:project_mobile_pdam/core/widget/app_state.dart';

abstract class AppStatePage<T extends StatefulWidget> extends AppState<T> {
  late final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  void initState() {
    super.initState();
    scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    AppSnackbar.scaffoldMessengerKeys.add(scaffoldMessengerKey);
  }

  @override
  void dispose() {
    super.dispose();
    AppSnackbar.scaffoldMessengerKeys.remove(scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Builder(builder: (innerContext) => buildPage(innerContext)),
    );
  }

  Widget buildPage(BuildContext context);
}
