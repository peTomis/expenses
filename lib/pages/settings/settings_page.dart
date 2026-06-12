import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/button/app_button.dart';
import '../../components/card/app_card.dart';
import '../../components/dev_logo/dev_logo.dart';
import '../../components/select/app_select.dart';
import '../../components/text_input/app_text_input.dart';
import '../../providers/category_provider.dart';
import '../../providers/color_provider.dart';
import '../../providers/financial_data_provider.dart';
import '../../providers/user_data_upload_provider.dart';
import '../../providers/username_provider.dart';
import '../auth/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: SettingsContent(showBackButton: showBackButton));
  }
}

class SettingsContent extends ConsumerWidget {
  const SettingsContent({super.key, this.showBackButton = true});

  final bool showBackButton;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final username = ref.read(usernameProvider.notifier);
    final auth = ref.read(authRepositoryProvider);

    try {
      await username.clearUsername();
      await auth.signOut();
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _uploadUserData(BuildContext context, WidgetRef ref) async {
    final uploaded = await ref
        .read(userDataUploadControllerProvider.notifier)
        .uploadCurrent();

    if (!context.mounted) {
      return;
    }

    final uploadState = ref.read(userDataUploadControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uploaded
              ? 'sync'
              : uploadState.status == UserDataUploadStatus.uploading
              ? 'sync'
              : 'sync issue',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final username = ref
        .watch(usernameProvider)
        .whenOrNull(data: (username) => username);
    final financialData = ref.watch(financialDataProvider);
    final selectedCurrency = financialData.accountData.currency;
    final categories = ref.watch(categoryProvider);
    final uploadState = ref.watch(userDataUploadControllerProvider);
    final textColor = ref.watch(appPrimaryTextColorProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (showBackButton) ...[
                        _PlainIconButton(
                          tooltip: 'Back',
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    maxWidth: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AccountInfoLine(
                          icon: Icons.person,
                          child: Text(
                            username ?? user?.email ?? 'Unknown user',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (user != null) ...[
                          const SizedBox(height: 12),
                          _UploadStatusLine(
                            state: uploadState,
                            onUploadPressed: () =>
                                _uploadUserData(context, ref),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsSection(
                    title: 'Currency',
                    titleIcon: Icons.payments_outlined,
                    titleColor: textColor,
                    child: AppSelect<CurrencyData>(
                      value: selectedCurrency,
                      items: CurrencyData.supportedCurrencies
                          .map(
                            (currency) => AppSelectItem(
                              value: currency,
                              label: currency.label,
                            ),
                          )
                          .toList(),
                      onChanged: ref
                          .read(financialDataProvider.notifier)
                          .setCurrency,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsSection(
                    title: 'Categories',
                    titleIcon: Icons.category_outlined,
                    titleColor: textColor,
                    child: _CategorySettingsButton(
                      categoryCount: categories.length,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const DevLogo(),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.child,
    this.title,
    this.titleIcon,
    this.titleColor,
  });

  final Widget child;
  final String? title;
  final IconData? titleIcon;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      maxWidth: double.infinity,
      padding: const EdgeInsets.all(16),
      title: title,
      titleIcon: titleIcon,
      titleColor: titleColor,
      titleIconColor: titleColor,
      titleStyle: Theme.of(context).textTheme.bodyMedium,
      child: child,
    );
  }
}

class _UploadStatusLine extends ConsumerWidget {
  const _UploadStatusLine({required this.state, required this.onUploadPressed});

  final UserDataUploadState state;
  final VoidCallback? onUploadPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final statusColor = _statusColor(textColor);

    return _AccountInfoLine(
      icon: _statusIcon,
      iconColor: statusColor,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onUploadPressed, child: const Text('Sync')),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    return switch (state.status) {
      UserDataUploadStatus.uploaded => Icons.cloud_done_outlined,
      UserDataUploadStatus.uploading => Icons.cloud_upload_outlined,
      UserDataUploadStatus.failed => Icons.cloud_off_outlined,
      UserDataUploadStatus.unavailable => Icons.cloud_off_outlined,
      UserDataUploadStatus.idle => Icons.cloud_queue_outlined,
    };
  }

  String get _statusText {
    return switch (state.status) {
      UserDataUploadStatus.uploaded =>
        state.lastUploadedAt == null
            ? 'sync'
            : 'sync ${_timeLabel(state.lastUploadedAt!)}',
      UserDataUploadStatus.uploading =>
        state.lastUploadedAt == null
            ? 'sync'
            : 'sync ${_timeLabel(state.lastUploadedAt!)}',
      UserDataUploadStatus.failed => 'sync issue',
      UserDataUploadStatus.unavailable => 'sync issue',
      UserDataUploadStatus.idle => 'never synced',
    };
  }

  String _timeLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Color _statusColor(Color textColor) {
    return switch (state.status) {
      UserDataUploadStatus.uploaded => textColor.withValues(alpha: 0.75),
      UserDataUploadStatus.uploading => textColor.withValues(alpha: 0.75),
      UserDataUploadStatus.failed => Colors.amberAccent,
      UserDataUploadStatus.unavailable => Colors.amberAccent,
      UserDataUploadStatus.idle => Colors.redAccent,
    };
  }
}

class _AccountInfoLine extends ConsumerWidget {
  const _AccountInfoLine({
    required this.icon,
    required this.child,
    this.iconColor,
  });

  final IconData icon;
  final Widget child;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, color: iconColor ?? textColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _CategorySettingsButton extends StatelessWidget {
  const _CategorySettingsButton({required this.categoryCount});

  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Edit categories ($categoryCount)',
      onPressed: () => _showCategoryListSheet(context),
    );
  }
}

Future<void> _showCategoryListSheet(BuildContext context) {
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
                        'Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                const SizedBox(height: 8),
                for (final category in categories)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minLeadingWidth: 32,
                    leading: Icon(category.icon, color: textColor),
                    onTap: () =>
                        _showCategorySheet(context, category: category),
                    title: Text(
                      category.name,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: textColor),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
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
  String? _nameError;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? Icons.label_outline;
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
            widget.category!.copyWith(name: name, icon: _selectedIcon),
          );
    } else {
      ref
          .read(categoryProvider.notifier)
          .addCategory(
            name: name,
            icon: _selectedIcon == Icons.label_outline ? null : _selectedIcon,
          );
    }
    unawaited(
      ref
          .read(userDataUploadControllerProvider.notifier)
          .uploadCurrentIfOnline(),
    );

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
      unawaited(
        ref
            .read(userDataUploadControllerProvider.notifier)
            .uploadCurrentIfOnline(),
      );
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
    unawaited(
      ref
          .read(userDataUploadControllerProvider.notifier)
          .uploadCurrentIfOnline(),
    );
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
                _CategoryIconGrid(
                  selectedIcon: _selectedIcon,
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

class _CategoryIconGrid extends ConsumerWidget {
  const _CategoryIconGrid({
    required this.selectedIcon,
    required this.onChanged,
  });

  final IconData selectedIcon;
  final ValueChanged<IconData> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final inputBackground = ref
        .watch(appPrimary500ColorProvider)
        .withValues(alpha: 0.5);
    final selectedColor = ref.watch(appPrimary300ColorProvider);
    final selectedTextColor = ref.watch(appPrimary500ColorProvider);

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final icon in _categoryIcons)
          _CategoryIconButton(
            icon: icon,
            selected: icon == selectedIcon,
            textColor: textColor,
            selectedColor: selectedColor,
            selectedTextColor: selectedTextColor,
            backgroundColor: inputBackground,
            onTap: () => onChanged(icon),
          ),
      ],
    );
  }
}

class _CategoryIconButton extends StatelessWidget {
  const _CategoryIconButton({
    required this.icon,
    required this.selected,
    required this.textColor,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color textColor;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 42,
        child: Material(
          color: selected ? selectedColor : backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Icon(
              icon,
              color: selected ? selectedTextColor : textColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

final _categoryIcons = {
  Icons.label_outline,
  ...categoryIconByName.values,
}.toList();

class _PlainIconButton extends ConsumerWidget {
  const _PlainIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: textColor, size: 24),
        ),
      ),
    );
  }
}
