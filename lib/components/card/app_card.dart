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
    this.titleTicker,
    this.titleSuffix,
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
  final Widget? titleTicker;
  final Widget? titleSuffix;
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
    final hasHeader =
        title != null ||
        titleLeading != null ||
        titleIcon != null ||
        titleTicker != null ||
        titleSuffix != null ||
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
                _AppCardHeader(
                  title: title,
                  leading: titleLeading,
                  icon: titleIcon,
                  ticker: titleTicker ?? titleSuffix,
                  trailing: titleTrailing,
                  titleStyle: titleStyle,
                  titleColor: titleColor,
                  iconColor: titleIconColor,
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

class _AppCardHeader extends StatelessWidget {
  const _AppCardHeader({
    required this.title,
    required this.leading,
    required this.icon,
    required this.ticker,
    required this.trailing,
    required this.titleStyle,
    required this.titleColor,
    required this.iconColor,
  });

  final String? title;
  final Widget? leading;
  final IconData? icon;
  final Widget? ticker;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedTitleStyle =
        (titleStyle ?? Theme.of(context).textTheme.headlineSmall)?.copyWith(
          color: titleColor,
        );

    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? titleColor, size: 22),
                const SizedBox(width: 8),
              ],
              if (title != null)
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    title!,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: resolvedTitleStyle,
                  ),
                ),
              if (ticker != null) ...[const SizedBox(width: 8), ticker!],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
