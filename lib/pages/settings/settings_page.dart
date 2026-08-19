import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/button/app_button.dart';
import '../../components/card/app_card.dart';
import '../../components/dev_logo/dev_logo.dart';
import '../../components/select/app_select.dart';
import '../../providers/category_provider.dart';
import '../../providers/color_provider.dart';
import '../../providers/data_backup_provider.dart';
import '../../providers/financial_data_provider.dart';
import '../../providers/username_provider.dart';
import 'widgets/category_sheets.dart';

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
      onPressed: () => showCategoryListSheet(context),
    );
  }
}

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
