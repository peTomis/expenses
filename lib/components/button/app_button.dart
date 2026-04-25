import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/color_provider.dart';

class AppButton extends ConsumerWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final fillColor = ref
        .watch(appPrimary300ColorProvider)
        .withValues(alpha: 1);
    final disabledColor = ref
        .watch(appPrimary300ColorProvider)
        .withValues(alpha: 0.45);

    final enabled = onPressed != null && !isLoading;

    final child = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: enabled ? 1 : 0.65,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? fillColor : disabledColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fillColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );

    final button = InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: child,
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
