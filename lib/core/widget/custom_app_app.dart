import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_stateless_widget.dart';

class CustomAppBar extends AppStatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? actionIcon;
  final Color? actionIconColor;
  final VoidCallback? onActionPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actionIcon,
    this.actionIconColor,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: textTheme(context).displayLarge),
      backgroundColor: color(context).primary[500],
      centerTitle: true,
      actions: actionIcon != null
          ? [
              IconButton(
                icon: Icon(actionIcon),
                color: actionIconColor ?? color(context).foreground[100],
                onPressed: onActionPressed,
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
