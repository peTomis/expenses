import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/color_provider.dart';

class AppTabBarItem {
  const AppTabBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppTabBar extends ConsumerWidget {
  const AppTabBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.onDoubleSelected,
  }) : assert(items.length > 0, 'AppTabBar requires at least one item.');

  final List<AppTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int>? onDoubleSelected;

  /// The bar's total footprint (including its own vertical padding), so
  /// callers can reserve exactly enough space for it when it floats over
  /// content (e.g. with `Scaffold.extendBody`).
  static const double totalHeight =
      _AppTabBarButton.itemHeight + _tabBarPadding * 2 + (kIsWeb ? 24 : 8) * 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final selectedColor = ref.watch(appPrimary300ColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);
    final tabBarHeight = _AppTabBarButton.itemHeight + _tabBarPadding * 2;
    final effectiveSelectedIndex = selectedIndex.clamp(0, items.length - 1);
    final naturalItemWidth = _AppTabBarButton.itemWidth;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: kIsWeb ? 24 : 8,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxBarWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth.clamp(0, 392).toDouble()
                  : 392.0;
              final naturalBarWidth =
                  items.length * naturalItemWidth + _tabBarPadding * 2;
              final barWidth = naturalBarWidth < maxBarWidth
                  ? naturalBarWidth
                  : maxBarWidth;
              final contentWidth = barWidth - _tabBarPadding * 2;
              final itemWidth = contentWidth / items.length;

              return SizedBox(
                width: barWidth,
                height: tabBarHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: _tabBarRadius,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: surfaceColor.withValues(alpha: 0.72),
                            borderRadius: _tabBarRadius,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.26),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(_tabBarPadding),
                      child: SizedBox(
                        width: contentWidth,
                        height: _AppTabBarButton.itemHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutBack,
                              left:
                                  effectiveSelectedIndex * itemWidth +
                                  (itemWidth - _AppTabBarButton.itemHeight) / 2,
                              top: 0,
                              child: _SelectedTabBubble(color: selectedColor),
                            ),
                            Row(
                              children: [
                                for (final indexedItem in items.indexed)
                                  _AppTabBarButton(
                                    item: indexedItem.$2,
                                    width: itemWidth,
                                    isSelected:
                                        indexedItem.$1 ==
                                        effectiveSelectedIndex,
                                    textColor: textColor,
                                    onTap: () => onSelected(indexedItem.$1),
                                    onDoubleTap:
                                        onDoubleSelected == null ||
                                            indexedItem.$1 !=
                                                effectiveSelectedIndex
                                        ? null
                                        : () =>
                                              onDoubleSelected!(indexedItem.$1),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AppTabBarButton extends StatelessWidget {
  const _AppTabBarButton({
    required this.item,
    required this.width,
    required this.isSelected,
    required this.textColor,
    required this.onTap,
    this.onDoubleTap,
  });

  static const double itemWidth = 56;
  static const double itemHeight = 52;

  final AppTabBarItem item;
  final double width;
  final bool isSelected;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? textColor
        : textColor.withValues(alpha: 0.58);

    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: SizedBox(
            width: width,
            height: itemHeight,
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                scale: isSelected ? 1.06 : 1,
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 26,
                  color: foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _tabBarPadding = 8.0;
const _tabBarRadius = BorderRadius.all(Radius.circular(999));

class _SelectedTabBubble extends StatelessWidget {
  const _SelectedTabBubble({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: const SizedBox(
        width: _AppTabBarButton.itemHeight,
        height: _AppTabBarButton.itemHeight,
      ),
    );
  }
}
