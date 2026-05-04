import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/color_provider.dart';

class AppCard extends ConsumerWidget {
  const AppCard({
    required this.child,
    super.key,
    this.title,
    this.titleLeading,
    this.titleIcon,
    this.titleTrailing,
    this.titleStyle,
    this.titleColor,
    this.titleIconColor,
    this.titleSpacing = 20,
    this.maxWidth = 420,
    this.padding = const EdgeInsets.all(20),
    this.elevation = 2,
    this.backgroundColor,
  });

  final String? title;
  final Widget child;
  final Widget? titleLeading;
  final IconData? titleIcon;
  final Widget? titleTrailing;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final Color? titleIconColor;
  final double titleSpacing;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBackgroundColor =
        backgroundColor ?? ref.watch(widgetBackgroundColorProvider);
    final resolvedTitleStyle =
        (titleStyle ?? Theme.of(context).textTheme.headlineSmall)?.copyWith(
          color: titleColor,
        );
    final hasHeader =
        title != null ||
        titleLeading != null ||
        titleIcon != null ||
        titleTrailing != null;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Card(
        elevation: elevation,
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasHeader) ...[
                Row(
                  children: [
                    if (titleLeading != null) ...[
                      titleLeading!,
                      const SizedBox(width: 8),
                    ],
                    if (titleIcon != null) ...[
                      Icon(
                        titleIcon,
                        color: titleIconColor ?? titleColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (title != null)
                      Expanded(
                        child: Text(
                          title!,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          style: resolvedTitleStyle,
                        ),
                      )
                    else
                      const Spacer(),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 12),
                      titleTrailing!,
                    ],
                  ],
                ),
                SizedBox(height: titleSpacing),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
