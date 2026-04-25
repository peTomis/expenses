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
  });

  final List<AppTabBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final selectedColor = ref.watch(appPrimary300ColorProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            for (final indexedItem in items.indexed)
              Expanded(
                child: _AppTabBarButton(
                  item: indexedItem.$2,
                  isSelected: indexedItem.$1 == selectedIndex,
                  textColor: textColor,
                  selectedColor: selectedColor,
                  onTap: () => onSelected(indexedItem.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppTabBarButton extends StatelessWidget {
  const _AppTabBarButton({
    required this.item,
    required this.isSelected,
    required this.textColor,
    required this.selectedColor,
    required this.onTap,
  });

  final AppTabBarItem item;
  final bool isSelected;
  final Color textColor;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? textColor
        : textColor.withValues(alpha: 0.62);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: 22,
              color: foregroundColor,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
