import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/dev_logo/dev_logo.dart';
import '../../components/select/app_select.dart';
import '../../providers/color_provider.dart';
import '../../providers/financial_data_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final username = ref
        .watch(usernameProvider)
        .whenOrNull(data: (username) => username);
    final financialData = ref.watch(financialDataProvider);
    final selectedCurrency = financialData.accountData.currency;
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Padding(
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: textColor.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.person, color: textColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              username ?? user?.email ?? 'Unknown user',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, color: textColor),
                            const SizedBox(width: 12),
                            Text(
                              'Currency',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppSelect<CurrencyData>(
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
                      ],
                    ),
                  ),
                  const Spacer(),
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

class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final surfaceColor = ref.watch(widgetBackgroundColorProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.14)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
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
