import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/category_provider.dart';
import '../../../providers/color_provider.dart';

/// A single transaction line: tinted category icon, merchant + subtitle,
/// and a colored amount on the trailing edge. Shared by the Home tab's
/// "Recent" list and the Transactions tab's day groups.
class TransactionRow extends ConsumerWidget {
  const TransactionRow({
    super.key,
    required this.category,
    required this.merchant,
    required this.subtitle,
    required this.amountLabel,
    required this.amountColor,
    this.scanned = false,
    this.onTap,
    this.dense = false,
  });

  final FinancialCategory category;
  final String merchant;
  final String subtitle;
  final String amountLabel;
  final Color amountColor;
  final bool scanned;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final iconSize = dense ? 34.0 : 38.0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(dense ? 15 : 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dense ? 15 : 16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 13,
            vertical: dense ? 11 : 12,
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(dense ? 11 : 12),
                ),
                child: Icon(
                  category.icon,
                  size: dense ? 18 : 20,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (dense
                                  ? Theme.of(context).textTheme.bodyMedium
                                  : Theme.of(context).textTheme.bodyLarge)
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subtitle,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                          ),
                        ),
                        if (scanned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: ref.watch(appPrimary300ColorProvider),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
