import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/card/app_card.dart';
import '../../providers/category_provider.dart';
import '../../providers/color_provider.dart';
import '../../providers/financial_data_provider.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({super.key, required this.entry});

  final FinancialDataEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);
    final currencySymbol = ref
        .watch(financialDataProvider)
        .accountData
        .currency
        .symbol;
    final categories = ref.watch(categoryProvider);
    final category =
        categories.where((c) => c.uuid == entry.category).firstOrNull ??
        uncategorizedCategory;
    final paymentMethod = PaymentMethodData.byKey(entry.paymentMethod);
    final isExpense = entry.amount < 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).pop(),
                    textColor: textColor,
                    surfaceColor: surfaceColor,
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    onTap: null,
                    textColor: textColor,
                    surfaceColor: surfaceColor,
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    onTap: null,
                    textColor: const Color(0xFFFF7043),
                    surfaceColor: surfaceColor,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(category.icon, size: 28, color: category.color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${isExpense ? '− ' : '+ '}$currencySymbol '
                      '${entry.amount.abs().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.merchant,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.timestamp.day} ${_monthNames[entry.timestamp.month - 1]} '
                      '${entry.timestamp.year} · '
                      '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                      '${entry.timestamp.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: textColor.withValues(alpha: 0.5)),
                    ),
                    if (entry.scanned) ...[
                      const SizedBox(height: 10),
                      _ScannedBadge(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              AppCard(
                maxWidth: double.infinity,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Category',
                      textColor: textColor,
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 17, color: category.color),
                          const SizedBox(width: 7),
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: textColor.withValues(alpha: 0.08)),
                    _InfoRow(
                      label: 'Paid with',
                      textColor: textColor,
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paymentMethod?.icon ?? Icons.help_outline,
                            size: 17,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            paymentMethod?.label ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: textColor.withValues(alpha: 0.08)),
                    _InfoRow(
                      label: 'Type',
                      textColor: textColor,
                      value: Text(
                        isExpense ? 'Expense' : 'Income',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.items != null && entry.items!.isNotEmpty) ...[
                const SizedBox(height: 14),
                AppCard(
                  maxWidth: double.infinity,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 19,
                              color: ref.watch(appPrimary300ColorProvider),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Receipt · ${entry.items!.length} items',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final item in entry.items!)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                child: Text(
                                  '${item.qty}×',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(color: textColor),
                                    children: [
                                      TextSpan(text: item.name),
                                      if (item.brandSize.isNotEmpty)
                                        TextSpan(
                                          text: ' ${item.brandSize}',
                                          style: TextStyle(
                                            color: textColor.withValues(alpha: 0.45),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                '$currencySymbol ${item.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textColor.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Divider(height: 1, color: textColor.withValues(alpha: 0.12)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                        child: Row(
                          children: [
                            Text(
                              'TOTAL',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: textColor.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$currencySymbol ${entry.amount.abs().toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Items keep the transaction's single category — tap any line to split "
                  'it out later.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: textColor.withValues(alpha: 0.4)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannedBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(appPrimary300ColorProvider);
    final foreground = ref.watch(appPrimary50ColorProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 15, color: foreground),
            const SizedBox(width: 6),
            Text(
              'Scanned · confirmed by you',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.textColor});

  final String label;
  final Widget value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor.withValues(alpha: 0.55)),
          ),
          const Spacer(),
          value,
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.textColor,
    required this.surfaceColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color textColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: textColor.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, size: 19, color: onTap == null ? textColor.withValues(alpha: 0.4) : textColor),
        ),
      ),
    );
  }
}
