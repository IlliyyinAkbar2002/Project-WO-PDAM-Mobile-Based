import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class ProgressCard extends StatefulWidget {
  final String type; // "start", "progress", "finish"
  final bool isFilled;
  final String? description;
  final String? dateTime;
  final int index;
  final VoidCallback onTap;

  const ProgressCard({
    super.key,
    required this.type,
    this.isFilled = false,
    this.description,
    required this.dateTime,
    this.index = 0,
    required this.onTap,
  });

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends AppStatePage<ProgressCard> {
  @override
  Widget buildPage(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(_getIcon(), color: _getColor()),
        title: Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deskripsi Pekerjaan",
                    style: textTheme.titleSmall?.copyWith(
                      color: color.foreground[300],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.description ?? "-",
                    style: textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Waktu",
                    style: textTheme.titleSmall?.copyWith(
                      color: color.foreground[300],
                    ),
                  ),
                  Text(widget.dateTime ?? "-", style: textTheme.labelLarge),
                ],
              ),
            ),
            Container(
              width: 70,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getColor(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.type,
                  // _getTitle(),
                  style: textTheme.bodySmall?.copyWith(
                    color: widget.type == "Selesai"
                        ? color.foreground[100]
                        : color.primary[500],
                  ),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: widget.onTap,
      ),
    );
  }

  Color? _getColor() {
    if (widget.isFilled) return Colors.grey.shade400;

    switch (widget.type) {
      case "Mulai":
        return color.status[2];
      // case "progress":
      //   return color.control;
      case "Selesai":
        return color.primary[500];
      default:
        return color.control;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case "Mulai":
        return Icons.play_arrow;
      // case "progress":
      //   return Icons.sync;
      case "Selesai":
        return Icons.check;
      default:
        return Icons.sync;
    }
  }
}
