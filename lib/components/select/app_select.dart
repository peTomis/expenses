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
  });

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
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : double.infinity;
        final selectedItem = items.where((item) => item.value == value).first;

        return MenuAnchor(
          crossAxisUnconstrained: false,
          alignmentOffset: const Offset(0, 4),
          style: MenuStyle(
            alignment: AlignmentDirectional.bottomStart,
            backgroundColor: WidgetStatePropertyAll(menuColor),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(4),
            fixedSize: WidgetStatePropertyAll(Size.fromWidth(width)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          menuChildren: items.map((item) {
            final selected = item.value == value;

            return SizedBox(
              width: width,
              height: 44,
              child: MenuItemButton(
                onPressed: () => onChanged(item.value),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    selected ? selectedColor.withValues(alpha: 1) : menuColor,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    selected ? selectedTextColor : textColor,
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  overlayColor: WidgetStatePropertyAll(
                    tapColor.withValues(alpha: 0.72),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.label, overflow: TextOverflow.ellipsis),
                ),
              ),
            );
          }).toList(),
          builder: (context, controller, child) {
            return SizedBox(
              width: width,
              height: 44,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: controller.isOpen ? controller.close : controller.open,
                  borderRadius: BorderRadius.circular(8),
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
}
