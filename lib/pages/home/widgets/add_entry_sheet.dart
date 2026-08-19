import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/button/app_button.dart';
import '../../../components/select/app_select.dart';
import '../../../components/text_input/app_text_input.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/color_provider.dart';
import '../../../providers/financial_data_provider.dart';

class AddFinancialDataEntrySheet extends ConsumerStatefulWidget {
  const AddFinancialDataEntrySheet({
    super.key,
    required this.account,
    required this.currencySymbol,
  });

  final int account;
  final String currencySymbol;

  @override
  ConsumerState<AddFinancialDataEntrySheet> createState() =>
      _AddFinancialDataEntrySheetState();
}

class _AddFinancialDataEntrySheetState
    extends ConsumerState<AddFinancialDataEntrySheet> {
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryUuid;
  String? _merchantError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _setAmountCents(0);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
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

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submit() {
    final merchant = _merchantController.text.trim();
    final amount = _amountCents / 100;
    final categories = ref.read(categoryProvider);
    final selectedCategoryUuid =
        _selectedCategoryUuid ?? categories.firstOrNull?.uuid;
    String? merchantError;
    String? amountError;

    if (merchant.isEmpty) {
      merchantError = 'Merchant is required.';
    }

    if (_amountCents <= 0) {
      amountError = 'Enter a positive amount.';
    }

    setState(() {
      _merchantError = merchantError;
      _amountError = amountError;
    });

    if (merchantError != null ||
        amountError != null ||
        selectedCategoryUuid == null) {
      return;
    }

    final signedAmount = _isExpense ? -amount : amount;
    ref
        .read(financialDataProvider.notifier)
        .addEntry(
          FinancialDataEntry(
            timestamp: _selectedDate,
            amount: signedAmount,
            account: widget.account,
            merchant: merchant,
            category: selectedCategoryUuid,
          ),
        );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Transaction added.')));
  }

  void _handleAmountChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final cents = digits.isEmpty ? 0 : int.parse(digits);
    _setAmountCents(cents);

    if (_amountError == null) {
      return;
    }

    setState(() {
      _amountError = null;
    });
  }

  void _setAmountCents(int cents) {
    final amountText = (cents / 100).toStringAsFixed(2);
    _amountController.value = TextEditingValue(
      text: amountText,
      selection: TextSelection.collapsed(offset: amountText.length),
    );
  }

  int get _amountCents {
    final digits = _amountController.text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final backgroundColor = ref.watch(appBackgroundColorProvider);
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final panelColor = ref.watch(appPrimary500ColorProvider);
    final selectedColor = ref.watch(appPrimary300ColorProvider);
    final categories = ref.watch(categoryProvider);
    final selectedCategory =
        categories
            .where(
              (category) =>
                  category.uuid ==
                  (_selectedCategoryUuid ?? categories.firstOrNull?.uuid),
            )
            .firstOrNull ??
        categories.firstOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add transaction',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.remove),
                      label: Text('Expense'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.add),
                      label: Text('Income'),
                    ),
                  ],
                  selected: {_isExpense},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isExpense = selection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return selectedColor;
                      }

                      return panelColor.withValues(alpha: 0.5);
                    }),
                    foregroundColor: WidgetStatePropertyAll(textColor),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SmartAmountInput(
                  controller: _amountController,
                  currencySymbol: widget.currencySymbol,
                  errorText: _amountError,
                  onChanged: _handleAmountChanged,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Date',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: panelColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.45),
                        ),
                      ),
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: textColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _dateLabel(_selectedDate),
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedCategory != null) ...[
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppSelect<FinancialCategory>(
                    value: selectedCategory,
                    items: categories
                        .map(
                          (category) => AppSelectItem(
                            value: category,
                            label: category.label,
                            icon: category.icon,
                          ),
                        )
                        .toList(),
                    onChanged: (category) {
                      setState(() {
                        _selectedCategoryUuid = category.uuid;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextInput(
                  controller: _merchantController,
                  label: 'Merchant',
                  placeholder: 'Coffee shop',
                  errorText: _merchantError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_merchantError == null) {
                      return;
                    }
                    setState(() {
                      _merchantError = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Add transaction', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SmartAmountInput extends ConsumerStatefulWidget {
  const SmartAmountInput({
    super.key,
    required this.controller,
    required this.currencySymbol,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final String currencySymbol;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String? errorText;

  @override
  ConsumerState<SmartAmountInput> createState() => _SmartAmountInputState();
}

class _SmartAmountInputState extends ConsumerState<SmartAmountInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ref.watch(appPrimaryTextColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              widget.currencySymbol,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textAlign: TextAlign.center,
                cursorColor: textColor,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  errorText: widget.errorText,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
