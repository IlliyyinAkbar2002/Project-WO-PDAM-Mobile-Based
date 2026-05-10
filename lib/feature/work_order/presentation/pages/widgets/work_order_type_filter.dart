import 'package:flutter/material.dart';
import 'package:project_mobile_pdam/core/widget/app_state_page.dart';

class WorkOrderTypeFilter extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onFilterSelected;
  final List<String> filterLabels;
  const WorkOrderTypeFilter({
    super.key,
    required this.selectedIndex,
    required this.onFilterSelected,
    required this.filterLabels,
  });

  @override
  State<WorkOrderTypeFilter> createState() => _WorkOrderTypeFilterState();
}

class _WorkOrderTypeFilterState extends AppStatePage<WorkOrderTypeFilter> {
  @override
  Widget buildPage(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: List.generate(widget.filterLabels.length, (index) {
          bool isActive = widget.selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onFilterSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2A83C6)
                      : const Color(0xFFD0E8FA),
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFF2D499B)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  widget.filterLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFFF7F7F7)
                        : const Color(0xFF5E718D),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
