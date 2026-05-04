import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/color_provider.dart';

class AppSelectItem<T> {
  const AppSelectItem({required this.value, required this.label});

  final T value;
  final String label;
}

class AppSelect<T> extends ConsumerWidget {
  const AppSelect({
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  }) : assert(items.length > 0, 'AppSelect requires at least one item.');

  final T value;
  final List<AppSelectItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final menuColor = ref.watch(appPrimary500ColorProvider);
    final tapColor = ref.watch(appPrimary300ColorProvider);
    final selectedColor = ref.watch(appPrimary400ColorProvider);
    final selectedTextColor = ref.watch(appPrimary50ColorProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : null;
        final selectedItem = _selectedItem;

        return MenuAnchor(
          crossAxisUnconstrained: false,
          alignmentOffset: const Offset(0, 4),
          style: MenuStyle(
            alignment: AlignmentDirectional.bottomStart,
            backgroundColor: WidgetStatePropertyAll(menuColor),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(4),
            fixedSize: width == null
                ? null
                : WidgetStatePropertyAll(Size.fromWidth(width)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: _borderRadius),
            ),
          ),
          menuChildren: [
            for (final item in items)
              _SelectMenuItem<T>(
                item: item,
                width: width,
                selected: item.value == value,
                menuColor: menuColor,
                selectedColor: selectedColor,
                textColor: textColor,
                selectedTextColor: selectedTextColor,
                overlayColor: tapColor.withValues(alpha: 0.72),
                onChanged: onChanged,
              ),
          ],
          builder: (context, controller, child) {
            return SizedBox(
              width: width,
              height: 44,
              child: Material(
                color: Colors.transparent,
                borderRadius: _borderRadius,
                child: InkWell(
                  onTap: controller.isOpen ? controller.close : controller.open,
                  borderRadius: _borderRadius,
                  overlayColor: WidgetStatePropertyAll(
                    tapColor.withValues(alpha: 0.72),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedItem.label,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Icon(
                          controller.isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: textColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  AppSelectItem<T> get _selectedItem {
    for (final item in items) {
      if (item.value == value) {
        return item;
      }
    }

    return items.first;
  }
}

const _borderRadius = BorderRadius.all(Radius.circular(8));
const _itemHeight = 44.0;
const _itemPadding = EdgeInsets.symmetric(horizontal: 12);

class _SelectMenuItem<T> extends StatelessWidget {
  const _SelectMenuItem({
    required this.item,
    required this.width,
    required this.selected,
    required this.menuColor,
    required this.selectedColor,
    required this.textColor,
    required this.selectedTextColor,
    required this.overlayColor,
    required this.onChanged,
  });

  final AppSelectItem<T> item;
  final double? width;
  final bool selected;
  final Color menuColor;
  final Color selectedColor;
  final Color textColor;
  final Color selectedTextColor;
  final Color overlayColor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _itemHeight,
      child: MenuItemButton(
        onPressed: () => onChanged(item.value),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            selected ? selectedColor.withValues(alpha: 1) : menuColor,
          ),
          foregroundColor: WidgetStatePropertyAll(
            selected ? selectedTextColor : textColor,
          ),
          padding: const WidgetStatePropertyAll(_itemPadding),
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(overlayColor),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(item.label, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
