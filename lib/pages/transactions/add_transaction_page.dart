import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/button/app_button.dart';
import '../../providers/category_provider.dart';
import '../../providers/color_provider.dart';
import '../../providers/financial_data_provider.dart';
import 'transaction_detail_page.dart';

/// Full-screen "Add transaction" flow — reached either from the tab bar's
/// Add action sheet, or from [ScanReceiptPage] after a receipt photo is
/// captured (in which case [scanned] pre-marks the entry and the fields are
/// left for the user to fill in manually; there's no OCR).
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key, this.scanned = false});

  final bool scanned;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryUuid;
  String _selectedPaymentKey = PaymentMethodData.amex.key;
  String? _merchantError;
  String? _amountError;
  int _typedCents = 0;

  final List<ReceiptItem> _draftItems = [];
  bool _itemFormOpen = false;
  int _formQty = 1;
  final _formNameController = TextEditingController();
  final _formBrandController = TextEditingController();
  final _formSizeController = TextEditingController();
  final _formPriceController = TextEditingController();

  bool get _hasItems => _draftItems.isNotEmpty;

  int get _itemsTotalCents =>
      _draftItems.fold(0, (a, i) => a + (i.price * 100).round());

  int get _effectiveCents => _hasItems ? _itemsTotalCents : _typedCents;

  @override
  void initState() {
    super.initState();
    _syncAmountDisplay();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _formNameController.dispose();
    _formBrandController.dispose();
    _formSizeController.dispose();
    _formPriceController.dispose();
    super.dispose();
  }

  void _syncAmountDisplay() {
    final cents = _effectiveCents;
    final text = (cents / 100).toStringAsFixed(2);
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() => _selectedDate = pickedDate);
  }

  void _addItem() {
    final name = _formNameController.text.trim();
    final price = double.tryParse(_formPriceController.text.replaceAll(',', '.'));

    if (name.isEmpty) {
      _flash('Give the row a name');
      return;
    }
    if (price == null || price <= 0) {
      _flash('Enter a price for the row');
      return;
    }

    setState(() {
      _draftItems.add(
        ReceiptItem(
          qty: _formQty,
          name: name,
          brand: _formBrandController.text.trim(),
          size: _formSizeController.text.trim(),
          price: price,
        ),
      );
      _formQty = 1;
      _formNameController.clear();
      _formBrandController.clear();
      _formSizeController.clear();
      _formPriceController.clear();
      _syncAmountDisplay();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _draftItems.removeAt(index);
      _syncAmountDisplay();
    });
  }

  void _flash(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    final categories = ref.read(categoryProvider);
    final selectedCategoryUuid = _selectedCategoryUuid ?? categories.firstOrNull?.uuid;
    final selectedCategory = categories
        .where((c) => c.uuid == selectedCategoryUuid)
        .firstOrNull;

    if (_effectiveCents <= 0) {
      _flash('Enter an amount or add a row');
      return;
    }
    if (selectedCategoryUuid == null || selectedCategory == null) {
      setState(() => _merchantError = null);
      _flash('Choose a category');
      return;
    }

    final merchant = _merchantController.text.trim().isEmpty
        ? selectedCategory.name
        : _merchantController.text.trim();
    final amount = (_isExpense ? -1 : 1) * _effectiveCents / 100;
    final accountData = ref.read(financialDataProvider).accountData;

    final entry = FinancialDataEntry(
      timestamp: _selectedDate,
      amount: amount,
      account: accountData.account.first,
      merchant: merchant,
      category: selectedCategoryUuid,
      paymentMethod: _selectedPaymentKey,
      items: _draftItems.isEmpty ? null : List.of(_draftItems),
      scanned: widget.scanned,
    );

    ref.read(financialDataProvider.notifier).addEntry(entry);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TransactionDetailPage(entry: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final panelColor = ref.watch(appPrimary500ColorProvider);
    final selectedColor = ref.watch(appPrimary300ColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);
    final currencySymbol = ref
        .watch(financialDataProvider)
        .accountData
        .currency
        .symbol;
    final categories = ref.watch(categoryProvider);
    _selectedCategoryUuid ??= categories.firstOrNull?.uuid;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add transaction',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: textColor.withValues(alpha: 0.14)),
                      ),
                      child: Icon(Icons.close, size: 19, color: textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, icon: Icon(Icons.remove), label: Text('Expense')),
                  ButtonSegment(value: false, icon: Icon(Icons.add), label: Text('Income')),
                ],
                selected: {_isExpense},
                onSelectionChanged: (s) => setState(() => _isExpense = s.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? selectedColor
                        : panelColor.withValues(alpha: 0.5);
                  }),
                  foregroundColor: WidgetStatePropertyAll(textColor),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AmountField(
                controller: _amountController,
                currencySymbol: currencySymbol,
                enabled: !_hasItems,
                errorText: _amountError,
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  setState(() {
                    _typedCents = digits.isEmpty ? 0 : int.parse(digits);
                    _amountError = null;
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                _hasItems
                    ? 'Total from ${_draftItems.length} ${_draftItems.length == 1 ? 'row' : 'rows'}'
                    : 'Tap the amount to type it',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: textColor.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _BorderedField(
                      icon: Icons.store_outlined,
                      textColor: textColor,
                      panelColor: panelColor,
                      child: TextField(
                        controller: _merchantController,
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Merchant',
                        ),
                        onChanged: (_) {
                          if (_merchantError != null) {
                            setState(() => _merchantError = null);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: _BorderedField(
                      icon: Icons.calendar_today_outlined,
                      textColor: textColor,
                      panelColor: panelColor,
                      child: Text(
                        _dateLabel(_selectedDate),
                        style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(text: 'PAID WITH', textColor: textColor),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PaymentMethodData.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (context, index) {
                    final method = PaymentMethodData.values[index];
                    final selected = method.key == _selectedPaymentKey;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPaymentKey = method.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: selected ? selectedColor : surfaceColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected ? selectedColor : textColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              method.icon,
                              size: 17,
                              color: selected ? Colors.white : textColor.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              method.label,
                              style: TextStyle(
                                color: selected ? Colors.white : textColor.withValues(alpha: 0.7),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(text: 'CATEGORY', textColor: textColor),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.92,
                children: [
                  for (final category in categories)
                    _CategoryChip(
                      category: category,
                      selected: category.uuid == _selectedCategoryUuid,
                      textColor: textColor,
                      surfaceColor: surfaceColor,
                      onTap: () => setState(() => _selectedCategoryUuid = category.uuid),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ITEMS${_hasItems ? ' · ${_draftItems.length}' : ''}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.42),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _itemFormOpen = !_itemFormOpen),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _itemFormOpen ? Icons.expand_less : Icons.add,
                          size: 17,
                          color: ref.watch(appPrimary50ColorProvider),
                        ),
                        Text(
                          _itemFormOpen ? 'Done' : 'Add row',
                          style: TextStyle(
                            color: ref.watch(appPrimary50ColorProvider),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_hasItems)
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: textColor.withValues(alpha: 0.1)),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      for (final entry in _draftItems.indexed)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${entry.$2.qty}×',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: textColor, fontSize: 13.5),
                                    children: [
                                      TextSpan(text: entry.$2.name),
                                      if (entry.$2.brandSize.isNotEmpty)
                                        TextSpan(
                                          text: ' ${entry.$2.brandSize}',
                                          style: TextStyle(color: textColor.withValues(alpha: 0.42)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                '$currencySymbol ${entry.$2.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeItem(entry.$1),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.close,
                                    size: 17,
                                    color: textColor.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Divider(height: 1, color: textColor.withValues(alpha: 0.14)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              'ITEM TOTAL',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$currencySymbol ${(_itemsTotalCents / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_itemFormOpen)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selectedColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _QtyStepper(
                            qty: _formQty,
                            textColor: textColor,
                            panelColor: panelColor,
                            onChanged: (v) => setState(() => _formQty = v),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _BorderedField(
                              textColor: textColor,
                              panelColor: panelColor,
                              child: TextField(
                                controller: _formNameController,
                                style: TextStyle(color: textColor, fontSize: 13.5),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Item name',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _BorderedField(
                              textColor: textColor,
                              panelColor: panelColor,
                              child: TextField(
                                controller: _formBrandController,
                                style: TextStyle(color: textColor, fontSize: 13.5),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Brand',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            flex: 4,
                            child: _BorderedField(
                              textColor: textColor,
                              panelColor: panelColor,
                              child: TextField(
                                controller: _formSizeController,
                                style: TextStyle(color: textColor, fontSize: 13.5),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: 'Size',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            flex: 5,
                            child: _BorderedField(
                              textColor: textColor,
                              panelColor: panelColor,
                              child: Row(
                                children: [
                                  Text(
                                    '€',
                                    style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _formPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      style: TextStyle(color: textColor, fontSize: 13.5),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: '0.00',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formNameController.text.trim().isEmpty
                                  ? 'e.g. 1× Yogurt Greco  Faye 200g  €4.21'
                                  : '$_formQty× ${_formNameController.text.trim()}',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.4),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _addItem,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Add row',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              AppButton(label: 'Add transaction', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currencySymbol,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String currencySymbol;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final textColor = ref.watch(appPrimaryTextColorProvider);
        final color = enabled ? textColor : Colors.white;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currencySymbol,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  isDense: true,
                  errorText: errorText,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BorderedField extends StatelessWidget {
  const _BorderedField({
    required this.child,
    required this.textColor,
    required this.panelColor,
    this.icon,
  });

  final Widget child;
  final Color textColor;
  final Color panelColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: panelColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor.withValues(alpha: 0.55)),
            const SizedBox(width: 8),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.textColor,
    required this.panelColor,
    required this.onChanged,
  });

  final int qty;
  final Color textColor;
  final Color panelColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: panelColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged((qty - 1).clamp(1, 99)),
            child: Icon(Icons.remove, size: 18, color: textColor.withValues(alpha: 0.6)),
          ),
          SizedBox(
            width: 26,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged((qty + 1).clamp(1, 99)),
            child: Icon(Icons.add, size: 18, color: textColor.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.textColor});

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: textColor.withValues(alpha: 0.42),
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.textColor,
    required this.surfaceColor,
    required this.onTap,
  });

  final FinancialCategory category;
  final bool selected;
  final Color textColor;
  final Color surfaceColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? category.color.withValues(alpha: 0.18) : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? category.color : textColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 21,
              color: selected ? category.color : textColor.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 5),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: selected ? textColor : textColor.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
