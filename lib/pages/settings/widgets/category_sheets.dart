import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/button/app_button.dart';
import '../../../components/select/app_select.dart';
import '../../../components/text_input/app_text_input.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/color_provider.dart';
import '../../../providers/financial_data_provider.dart';
import 'category_pickers.dart';

Future<void> showCategoryListSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CategoryListSheet(),
  );
}

class _CategoryListSheet extends ConsumerWidget {
  const _CategoryListSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final backgroundColor = ref.watch(appBackgroundColorProvider);
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final categories = ref.watch(categoryProvider);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Material(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Categories',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add category',
                        onPressed: () => _showCategorySheet(context),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        minLeadingWidth: 32,
                        leading: Icon(category.icon, color: category.color),
                        onTap: () =>
                            _showCategorySheet(context, category: category),
                        title: Text(
                          category.name,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: textColor),
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showCategorySheet(
  BuildContext context, {
  FinancialCategory? category,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CategorySheet(category: category),
  );
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({this.category});

  final FinancialCategory? category;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  late final TextEditingController _nameController;

  late IconData _selectedIcon;
  late Color _selectedColor;
  String? _nameError;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? Icons.label_outline;
    _selectedColor = widget.category?.color ?? const Color(0xFF607D8B);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    String? nameError;

    if (name.isEmpty) {
      nameError = 'Name is required.';
    }

    setState(() {
      _nameError = nameError;
    });

    if (nameError != null) {
      return;
    }

    if (_isEditing) {
      ref
          .read(categoryProvider.notifier)
          .updateCategory(
            widget.category!.copyWith(
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
            ),
          );
    } else {
      ref
          .read(categoryProvider.notifier)
          .addCategory(
            name: name,
            icon: _selectedIcon == Icons.label_outline ? null : _selectedIcon,
            color: _selectedColor,
          );
    }

    Navigator.of(context).pop();
  }

  Future<void> _deleteCategory() async {
    final category = widget.category;
    if (category == null) {
      return;
    }

    final categories = ref.read(categoryProvider);
    if (categories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one category.')),
      );
      return;
    }

    final entryCount = ref
        .read(financialDataProvider.notifier)
        .entryCountForCategory(category.uuid);

    if (entryCount == 0) {
      ref.read(categoryProvider.notifier).removeCategory(category.uuid);
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final result = await showModalBottomSheet<_DeleteCategoryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _DeleteCategorySheet(category: category, entryCount: entryCount),
    );

    if (result == null || !mounted) {
      return;
    }

    ref
        .read(financialDataProvider.notifier)
        .replaceCategory(category.uuid, result.replacementCategoryUuid);
    ref.read(categoryProvider.notifier).removeCategory(category.uuid);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final backgroundColor = ref.watch(appBackgroundColorProvider);
    final textColor = ref.watch(appPrimaryTextColorProvider);

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
                        _isEditing ? 'Edit category' : 'Add category',
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
                const SizedBox(height: 16),
                ColorPicker(
                  color: _selectedColor,
                  onChanged: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                ),
                const SizedBox(height: 12),
                CategoryIconGrid(
                  selectedIcon: _selectedIcon,
                  selectedColor: _selectedColor,
                  onChanged: (icon) {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                ),
                const SizedBox(height: 12),
                AppTextInput(
                  controller: _nameController,
                  label: 'Name',
                  placeholder: 'Category name',
                  errorText: _nameError,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_nameError == null) {
                      return;
                    }
                    setState(() {
                      _nameError = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: _isEditing ? 'Save category' : 'Add category',
                  onPressed: _submit,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _deleteCategory,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete category'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteCategoryResult {
  const _DeleteCategoryResult({this.replacementCategoryUuid});

  final String? replacementCategoryUuid;
}

class _DeleteCategorySheet extends ConsumerStatefulWidget {
  const _DeleteCategorySheet({
    required this.category,
    required this.entryCount,
  });

  final FinancialCategory category;
  final int entryCount;

  @override
  ConsumerState<_DeleteCategorySheet> createState() =>
      _DeleteCategorySheetState();
}

class _DeleteCategorySheetState extends ConsumerState<_DeleteCategorySheet> {
  String? _replacementCategoryUuid;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final backgroundColor = ref.watch(appBackgroundColorProvider);
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final replacementCategories = ref
        .watch(categoryProvider)
        .where((category) => category.uuid != widget.category.uuid)
        .toList();
    final selectedReplacement =
        replacementCategories
            .where(
              (category) =>
                  category.uuid ==
                  (_replacementCategoryUuid ??
                      replacementCategories.firstOrNull?.uuid),
            )
            .firstOrNull ??
        replacementCategories.firstOrNull;

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
                        'Delete category',
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
                Text(
                  '${widget.entryCount} transaction${widget.entryCount == 1 ? '' : 's'} use ${widget.category.name}.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: textColor),
                ),
                if (selectedReplacement != null) ...[
                  const SizedBox(height: 16),
                  AppSelect<FinancialCategory>(
                    value: selectedReplacement,
                    items: replacementCategories
                        .map(
                          (category) => AppSelectItem(
                            value: category,
                            label: category.name,
                            icon: category.icon,
                          ),
                        )
                        .toList(),
                    onChanged: (category) {
                      setState(() {
                        _replacementCategoryUuid = category.uuid;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Move transactions',
                    onPressed: () => Navigator.of(context).pop(
                      _DeleteCategoryResult(
                        replacementCategoryUuid: selectedReplacement.uuid,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(const _DeleteCategoryResult()),
                  icon: const Icon(Icons.link_off),
                  label: const Text('Remove from transactions'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
