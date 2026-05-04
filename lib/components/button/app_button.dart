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
    final button = Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        borderRadius: _borderRadius,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: _borderRadius,
          child: AnimatedOpacity(
            duration: _fadeDuration,
            opacity: enabled ? 1 : 0.65,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: enabled ? fillColor : disabledColor,
                borderRadius: _borderRadius,
                border: Border.all(color: fillColor),
              ),
              child: Padding(
                padding: _contentPadding,
                child: Center(
                  child: _AppButtonContent(
                    isLoading: isLoading,
                    label: label,
                    textColor: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

const _borderRadius = BorderRadius.all(Radius.circular(8));
const _contentPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
const _fadeDuration = Duration(milliseconds: 120);

class _AppButtonContent extends StatelessWidget {
  const _AppButtonContent({
    required this.isLoading,
    required this.label,
    required this.textColor,
  });

  final bool isLoading;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
      );
    }

    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
