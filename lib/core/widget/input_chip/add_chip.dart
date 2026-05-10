import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_stateless_widget.dart';

class AddChip extends AppStatelessWidget {
  const AddChip({
    super.key,
    required this.chip,
    required this.onDeleted,
    required this.onSelected,
  });

  final String chip;
  final ValueChanged<String> onDeleted;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), // gray-50
          border: Border.all(
            color: const Color(0xFF34A853),
            width: 1,
          ), // Green border
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chip,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D499B),
                letterSpacing: -0.2,
                height: 1.71,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onDeleted(chip),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF2D499B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
