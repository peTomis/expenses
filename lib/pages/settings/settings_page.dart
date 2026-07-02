import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/button/app_button.dart';
import '../../components/card/app_card.dart';
import '../../components/dev_logo/dev_logo.dart';
import '../../components/select/app_select.dart';
import '../../components/text_input/app_text_input.dart';
import '../../providers/category_provider.dart';
import '../../providers/color_provider.dart';
import '../../providers/data_backup_provider.dart';
import '../../providers/financial_data_provider.dart';
import '../../providers/username_provider.dart';

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
    await ref.read(usernameProvider.notifier).clearUsername();
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final exported = await ref
        .read(dataBackupControllerProvider.notifier)
        .exportBackup();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(exported ? 'Backup saved' : 'Export cancelled')),
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final imported = await ref
        .read(dataBackupControllerProvider.notifier)
        .importBackup();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(imported ? 'Backup imported' : 'Import cancelled'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref
        .watch(usernameProvider)
        .whenOrNull(data: (username) => username);
    final financialData = ref.watch(financialDataProvider);
    final selectedCurrency = financialData.accountData.currency;
    final categories = ref.watch(categoryProvider);
    final backupState = ref.watch(dataBackupControllerProvider);
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
                            username ?? 'Unknown user',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BackupStatusLine(
                          state: backupState,
                          onExportPressed: () => _exportBackup(context, ref),
                          onImportPressed: () => _importBackup(context, ref),
                        ),
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
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () => _logout(context, ref),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.logout, size: 24),
                      label: Text(
                        'Logout',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
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

class _BackupStatusLine extends ConsumerWidget {
  const _BackupStatusLine({
    required this.state,
    required this.onExportPressed,
    required this.onImportPressed,
  });

  final DataBackupState state;
  final VoidCallback? onExportPressed;
  final VoidCallback? onImportPressed;

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
          TextButton(
            onPressed: state.isWorking ? null : onImportPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: const Text('Import'),
          ),
          TextButton(
            onPressed: state.isWorking ? null : onExportPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon {
    return switch (state.status) {
      DataBackupStatus.done => Icons.cloud_done_outlined,
      DataBackupStatus.working => Icons.cloud_upload_outlined,
      DataBackupStatus.failed => Icons.cloud_off_outlined,
      DataBackupStatus.idle => Icons.cloud_queue_outlined,
    };
  }

  String get _statusText {
    return switch (state.status) {
      DataBackupStatus.done =>
        state.lastBackupAt == null
            ? 'Backed up'
            : 'Backed up ${_timeLabel(state.lastBackupAt!)}',
      DataBackupStatus.working => 'Working...',
      DataBackupStatus.failed => state.message ?? 'Backup issue',
      DataBackupStatus.idle => 'Never backed up',
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
      DataBackupStatus.done => textColor.withValues(alpha: 0.75),
      DataBackupStatus.working => textColor.withValues(alpha: 0.75),
      DataBackupStatus.failed => Colors.amberAccent,
      DataBackupStatus.idle => Colors.redAccent,
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
                _ColorPicker(
                  color: _selectedColor,
                  onChanged: (color) {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _CategoryIconGrid(
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

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.color, required this.onChanged});

  final Color color;
  final ValueChanged<Color> onChanged;

  void _onSVPan(HSVColor hsv, Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(s).withValue(v).toColor());
  }

  void _onHuePan(HSVColor hsv, Offset local, Size size) {
    final hue = (local.dx / size.width * 360.0).clamp(0.0, 360.0);
    onChanged(hsv.withHue(hue).toColor());
  }

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(color);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const h = 160.0;
            final size = Size(constraints.maxWidth, h);
            return GestureDetector(
              onPanStart: (d) => _onSVPan(hsv, d.localPosition, size),
              onPanUpdate: (d) => _onSVPan(hsv, d.localPosition, size),
              onTapDown: (d) => _onSVPan(hsv, d.localPosition, size),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  size: size,
                  painter: _SVPickerPainter(
                    hue: hsv.hue,
                    saturation: hsv.saturation,
                    value: hsv.value,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const h = 20.0;
            final size = Size(constraints.maxWidth, h);
            return GestureDetector(
              onPanStart: (d) => _onHuePan(hsv, d.localPosition, size),
              onPanUpdate: (d) => _onHuePan(hsv, d.localPosition, size),
              onTapDown: (d) => _onHuePan(hsv, d.localPosition, size),
              child: CustomPaint(
                size: size,
                painter: _HuePickerPainter(hue: hsv.hue),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SVPickerPainter extends CustomPainter {
  const _SVPickerPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final cx = saturation * size.width;
    final cy = (1.0 - value) * size.height;
    canvas.drawCircle(
      Offset(cx, cy),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      8,
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _SVPickerPainter old) =>
      old.hue != hue || old.saturation != saturation || old.value != value;
}

class _HuePickerPainter extends CustomPainter {
  const _HuePickerPainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            for (var i = 0; i <= 6; i++)
              HSVColor.fromAHSV(1.0, i * 60.0, 1.0, 1.0).toColor(),
          ],
        ).createShader(rect),
    );

    final tx = (hue / 360.0) * size.width;
    final ty = size.height / 2;
    final r = size.height / 2 + 2;

    canvas.drawCircle(
      Offset(tx, ty),
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(tx, ty),
      r - 2,
      Paint()..color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePickerPainter old) => old.hue != hue;
}

class _CategoryIconGrid extends ConsumerWidget {
  const _CategoryIconGrid({
    required this.selectedIcon,
    required this.selectedColor,
    required this.onChanged,
  });

  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final inputBackground = ref
        .watch(appPrimary500ColorProvider)
        .withValues(alpha: 0.5);

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
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color textColor;
  final Color selectedColor;
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
              color: selected ? Colors.white : textColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

final _categoryIcons = [Icons.label_outline, ...categoryIcons];

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
