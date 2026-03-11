import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_stateless_widget.dart';

class InputSuggestion extends AppStatelessWidget {
  const InputSuggestion(this.suggestion, {super.key, this.onTap});

  final String suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ObjectKey(suggestion),
      leading: CircleAvatar(
        child: Text(suggestion.toString()[0].toUpperCase()),
      ),
      title: Text(suggestion),
      onTap: onTap,
    );
  }
}
