import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A Speed Dial FAB widget that expands to show multiple action buttons
/// in a radial/vertical arrangement.
class SpeedDialFab extends StatefulWidget {
  /// List of action items to display when expanded
  final List<SpeedDialItem> items;

  /// Main button background color
  final Color? backgroundColor;

  /// Main button icon color
  final Color? iconColor;

  /// Animation duration
  final Duration animationDuration;

  /// Distance between main FAB and child FABs
  final double childrenDistance;

  /// Whether to show labels for children
  final bool showLabels;

  /// Tooltip for the main FAB
  final String? tooltip;

  /// Elevation of the FAB
  final double elevation;

  const SpeedDialFab({
    super.key,
    required this.items,
    this.backgroundColor,
    this.iconColor,
    this.animationDuration = const Duration(milliseconds: 250),
    this.childrenDistance = 70.0,
    this.showLabels = true,
    this.tooltip,
    this.elevation = 6.0,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: math.pi / 4, // 45 degrees for X icon effect
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.backgroundColor ?? const Color(0xff2d499b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Child FABs
        ..._buildExpandingActions(primaryColor),
        // Main FAB
        _buildMainFab(primaryColor, theme),
      ],
    );
  }

  List<Widget> _buildExpandingActions(Color primaryColor) {
    final List<Widget> children = [];

    for (int i = widget.items.length - 1; i >= 0; i--) {
      final item = widget.items[i];
      children.add(
        _buildExpandingAction(item: item, index: i, primaryColor: primaryColor),
      );
    }

    return children;
  }

  Widget _buildExpandingAction({
    required SpeedDialItem item,
    required int index,
    required Color primaryColor,
  }) {
    // Staggered animation for each child
    final delay = index / widget.items.length;
    final itemAnimation = CurvedAnimation(
      parent: _expandAnimation,
      curve: Interval(
        delay * 0.5,
        0.5 + delay * 0.5,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        final opacity = itemAnimation.value;
        final scale = itemAnimation.value;
        final translateY = (1 - itemAnimation.value) * 20;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(scale: scale.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            if (widget.showLabels && item.label != null)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  item.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Child FAB
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                heroTag: 'speed_dial_child_$index',
                elevation: 4,
                backgroundColor: item.backgroundColor ?? primaryColor,
                onPressed: () {
                  _close();
                  item.onTap?.call();
                },
                child: _buildItemIcon(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemIcon(SpeedDialItem item) {
    if (item.iconAsset != null) {
      return Image.asset(
        item.iconAsset!,
        width: 24,
        height: 24,
        color: item.iconColor ?? Colors.white,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default icon if asset not found
          return Icon(
            item.fallbackIcon ?? Icons.add,
            color: item.iconColor ?? Colors.white,
            size: 24,
          );
        },
      );
    } else if (item.icon != null) {
      return Icon(item.icon, color: item.iconColor ?? Colors.white, size: 24);
    } else if (item.customChild != null) {
      return item.customChild!;
    }
    return Icon(Icons.add, color: item.iconColor ?? Colors.white);
  }

  Widget _buildMainFab(Color primaryColor, ThemeData theme) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        heroTag: 'speed_dial_main',
        elevation: widget.elevation,
        backgroundColor: _isOpen ? const Color(0xFF3B82F6) : primaryColor,
        tooltip: widget.tooltip,
        onPressed: _toggle,
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: _isOpen
                  ? Icon(
                      Icons.close,
                      key: const ValueKey('close'),
                      color: widget.iconColor ?? Colors.white,
                    )
                  : Icon(
                      Icons.menu,
                      key: const ValueKey('menu'),
                      color: widget.iconColor ?? Colors.white,
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// A single item in the Speed Dial menu
class SpeedDialItem {
  /// Label text shown next to the FAB
  final String? label;

  /// Icon to display (if not using asset)
  final IconData? icon;

  /// Path to asset image
  final String? iconAsset;

  /// Fallback icon if asset fails to load
  final IconData? fallbackIcon;

  /// Custom widget to use instead of icon
  final Widget? customChild;

  /// Background color for this item's FAB
  final Color? backgroundColor;

  /// Icon/asset tint color
  final Color? iconColor;

  /// Callback when this item is tapped
  final VoidCallback? onTap;

  const SpeedDialItem({
    this.label,
    this.icon,
    this.iconAsset,
    this.fallbackIcon,
    this.customChild,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });
}
