import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/button/app_button.dart';
import '../../components/card/app_card.dart';
import '../../components/dev_logo/dev_logo.dart';
import '../../components/text_input/app_text_input.dart';
import '../../i18n/app_localizations.dart';
import '../../providers/color_provider.dart';
import '../../providers/username_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _usernameController = TextEditingController();

  bool _isSubmitting = false;
  String? _usernameError;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _usernameError = l10n.text('auth.usernameRequired');
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await ref.read(usernameProvider.notifier).setUsername(username);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/logo.svg',
                        width: 128,
                        height: 128,
                        colorFilter: ColorFilter.mode(
                          ref.watch(appPrimaryTextColorProvider),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppCard(
                        title: l10n.text('auth.localTitle'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppTextInput(
                              controller: _usernameController,
                              label: l10n.text('auth.usernameLabel'),
                              placeholder: l10n.text(
                                'auth.usernamePlaceholder',
                              ),
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              enableSuggestions: false,
                              errorText: _usernameError,
                              onSubmitted: (_) => _submit(),
                              onChanged: (_) {
                                if (_usernameError == null) {
                                  return;
                                }
                                setState(() {
                                  _usernameError = null;
                                });
                              },
                            ),
                            const SizedBox(height: 28),
                            AppButton(
                              label: _isSubmitting
                                  ? l10n.text('auth.pleaseWait')
                                  : l10n.text('auth.localButton'),
                              isLoading: _isSubmitting,
                              onPressed: _isSubmitting ? null : _submit,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
}
