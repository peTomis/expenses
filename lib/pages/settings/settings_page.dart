import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/card/app_card.dart';
import '../../components/dev_logo/dev_logo.dart';
import '../../providers/category_provider.dart';
import '../../providers/color_provider.dart';
import '../../providers/data_backup_provider.dart';
import '../../providers/drive_sync_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref
        .watch(usernameProvider)
        .whenOrNull(data: (username) => username);
    final financialData = ref.watch(financialDataProvider);
    final selectedCurrency = financialData.accountData.currency;
    final categories = ref.watch(categoryProvider);
    final backupState = ref.watch(dataBackupControllerProvider);
    final driveSyncState = ref.watch(driveSyncControllerProvider);
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppCard(
              maxWidth: double.infinity,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ref
                          .watch(appPrimary300ColorProvider)
                          .withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(username),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ref.watch(appPrimary50ColorProvider),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username ?? 'Unknown user',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Main account · ${selectedCurrency.name}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: textColor.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: textColor.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    value: '${categories.length}',
                    onTap: () => showCategoryListSheet(context),
                  ),
                  _rowDivider(textColor),
                  _SettingsRow(
                    icon: Icons.payments_outlined,
                    label: 'Currency',
                    value: selectedCurrency.label,
                    onTap: () => _openCurrencySheet(context, ref),
                  ),
                  _rowDivider(textColor),
                  _SettingsRow(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Receipt scanning',
                    value: 'On',
                    onTap: null,
                  ),
                  _rowDivider(textColor),
                  _SettingsRow(
                    icon: _driveSyncIcon(driveSyncState),
                    label: 'Cloud sync',
                    value: _driveSyncValue(driveSyncState),
                    onTap: () => _openDriveSyncSheet(context, ref),
                  ),
                  _rowDivider(textColor),
                  _SettingsRow(
                    icon: _backupIcon(backupState),
                    label: 'Backup',
                    value: _backupValue(backupState),
                    onTap: () => _openBackupSheet(context, ref),
                  ),
                  _rowDivider(textColor),
                  const _SettingsRow(
                    icon: Icons.palette_outlined,
                    label: 'Appearance',
                    value: 'Dark',
                    onTap: null,
                  ),
                ],
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
            const SizedBox(height: 24),
            const DevLogo(),
          ],
        ),
      ),
    );
  }

  IconData _driveSyncIcon(DriveSyncState state) {
    return switch (state.status) {
      DriveSyncStatus.synced => Icons.cloud_done_outlined,
      DriveSyncStatus.syncing => Icons.sync,
      DriveSyncStatus.error => Icons.cloud_off_outlined,
      DriveSyncStatus.idle => Icons.cloud_queue_outlined,
      DriveSyncStatus.signedOut => Icons.cloud_outlined,
    };
  }

  String _driveSyncValue(DriveSyncState state) {
    return switch (state.status) {
      DriveSyncStatus.synced =>
        state.lastSyncedAt == null
            ? 'Synced'
            : 'Synced ${_formatTimeLabel(state.lastSyncedAt!)}',
      DriveSyncStatus.syncing => 'Syncing...',
      DriveSyncStatus.error => 'Issue',
      DriveSyncStatus.idle => 'Connected',
      DriveSyncStatus.signedOut => 'Not connected',
    };
  }

  IconData _backupIcon(DataBackupState state) {
    return switch (state.status) {
      DataBackupStatus.done => Icons.cloud_done_outlined,
      DataBackupStatus.working => Icons.cloud_upload_outlined,
      DataBackupStatus.failed => Icons.cloud_off_outlined,
      DataBackupStatus.idle => Icons.cloud_queue_outlined,
    };
  }

  String _backupValue(DataBackupState state) {
    return switch (state.status) {
      DataBackupStatus.done =>
        state.lastBackupAt == null
            ? 'Backed up'
            : _formatTimeLabel(state.lastBackupAt!),
      DataBackupStatus.working => 'Working...',
      DataBackupStatus.failed => 'Issue',
      DataBackupStatus.idle => 'Never',
    };
  }

  void _openCurrencySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _OptionSheet(
        title: 'Currency',
        options: [
          for (final currency in CurrencyData.supportedCurrencies)
            _SheetOption(
              label: currency.label,
              selected:
                  currency ==
                  ref.read(financialDataProvider).accountData.currency,
              onTap: () {
                ref.read(financialDataProvider.notifier).setCurrency(currency);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    );
  }

  void _openDriveSyncSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (sheetContext, sheetRef, _) {
            final state = sheetRef.watch(driveSyncControllerProvider);
            final signedIn = state.status != DriveSyncStatus.signedOut;
            final isBusy = state.isSyncing;

            return _OptionSheet(
              title: 'Cloud sync',
              subtitle: signedIn
                  ? (state.accountEmail ?? 'Connected')
                  : 'Not connected',
              options: [
                if (signedIn) ...[
                  _SheetOption(
                    label: 'Sync now',
                    icon: Icons.sync,
                    onTap: isBusy
                        ? null
                        : () async {
                            await sheetRef
                                .read(driveSyncControllerProvider.notifier)
                                .syncNow();
                          },
                  ),
                  _SheetOption(
                    label: 'Sign out',
                    icon: Icons.logout,
                    onTap: isBusy
                        ? null
                        : () async {
                            await sheetRef
                                .read(driveSyncControllerProvider.notifier)
                                .signOut();
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                  ),
                ] else
                  _SheetOption(
                    label: 'Sign in',
                    icon: Icons.login,
                    onTap: isBusy
                        ? null
                        : () async {
                            await sheetRef
                                .read(driveSyncControllerProvider.notifier)
                                .signIn();
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _openBackupSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _OptionSheet(
        title: 'Backup',
        options: [
          _SheetOption(
            label: 'Export backup',
            icon: Icons.upload_outlined,
            onTap: () async {
              final exported = await ref
                  .read(dataBackupControllerProvider.notifier)
                  .exportBackup();
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      exported ? 'Backup saved' : 'Export cancelled',
                    ),
                  ),
                );
              }
            },
          ),
          _SheetOption(
            label: 'Import backup',
            icon: Icons.download_outlined,
            onTap: () async {
              final imported = await ref
                  .read(dataBackupControllerProvider.notifier)
                  .importBackup();
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      imported ? 'Backup imported' : 'Import cancelled',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

String _initials(String? username) {
  if (username == null || username.trim().isEmpty) {
    return '?';
  }
  final parts = username.trim().split(RegExp(r'\s+'));
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

String _formatTimeLabel(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Widget _rowDivider(Color textColor) {
  return Divider(height: 1, color: textColor.withValues(alpha: 0.07));
}

class _SettingsRow extends ConsumerWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textColor.withValues(alpha: 0.6)),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.45),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: textColor.withValues(alpha: 0.3),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSheet extends ConsumerWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<_SheetOption> options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final backgroundColor = ref.watch(appPrimary500ColorProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                for (final option in options) option,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends ConsumerWidget {
  const _SheetOption({
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final accent = ref.watch(appPrimary300ColorProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: textColor.withValues(alpha: 0.7)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onTap == null
                        ? textColor.withValues(alpha: 0.35)
                        : textColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, size: 18, color: accent),
            ],
          ),
        ),
      ),
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
