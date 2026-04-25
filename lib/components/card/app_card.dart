import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/color_provider.dart';

class AppCard extends ConsumerWidget {
  const AppCard({
    required this.title,
    required this.child,
    super.key,
    this.maxWidth = 420,
    this.padding = const EdgeInsets.all(20),
    this.elevation = 2,
  });

  final String title;
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final double elevation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBackgroundColor = ref.watch(widgetBackgroundColorProvider);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Card(
        elevation: elevation,
        color: cardBackgroundColor,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
