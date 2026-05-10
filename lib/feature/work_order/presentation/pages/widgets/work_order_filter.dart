import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class WorkOrderFilter extends StatefulWidget {
  final List<String> filterLabels;
  final Function(int, int) onFilterSelected;

  const WorkOrderFilter({
    super.key,
    required this.onFilterSelected,
    required this.filterLabels,
  });

  @override
  State<WorkOrderFilter> createState() => _WorkOrderFilterState();
}

class _WorkOrderFilterState extends AppStatePage<WorkOrderFilter> {
  int _selectedIndex = 0;
  int _subFilterIndex = 0;

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      children: [
        // Filter Utama
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color.fromRGBO(45, 73, 155, 1),
          child: Row(
            children: List.generate(widget.filterLabels.length, (index) {
              bool isActive = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                      _subFilterIndex = 0;
                    });
                    widget.onFilterSelected(_selectedIndex, _subFilterIndex);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      widget.filterLabels[index],
                      textAlign: TextAlign.center,
                      style: textTheme.displayMedium!.copyWith(
                        color: isActive
                            ? const Color(0xFF3ABFEF) // Cyan color from Figma
                            : color.foreground[100],
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
