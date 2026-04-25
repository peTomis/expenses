import 'package:expenses/providers/color_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/button/app_button.dart';
import '../../components/card/app_card.dart';
import '../../components/dev_logo/dev_logo.dart';
import '../../components/text_input/app_text_input.dart';
import '../../i18n/app_localizations.dart';
import '../../providers/username_provider.dart';
import 'auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) {
        ref.read(authFormProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final authForm = ref.read(authFormProvider);
    if (!_validateInputs() || authForm.isSubmitting) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (authForm.isLocalMode) {
        await ref.read(usernameProvider.notifier).setUsername(email);
        return;
      }

      ref.read(authFormProvider.notifier).setSubmitting(true);

      final auth = ref.read(authRepositoryProvider);
      if (authForm.isLoginMode) {
        await auth.signIn(email: email, password: password);
        final username = auth.currentUser?.email ?? email;
        await ref.read(usernameProvider.notifier).setUsername(username);
      } else {
        await auth.signUp(email: email, password: password);
      }

      if (!mounted) {
        return;
      }

      if (!authForm.isLoginMode && !authForm.isLocalMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.text('auth.registerSuccess'))),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('auth.unexpectedError'))),
      );
    } finally {
      if (mounted) {
        ref.read(authFormProvider.notifier).setSubmitting(false);
      }
    }
  }

  bool _validateInputs() {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authForm = ref.read(authFormProvider);

    String? emailError;
    String? passwordError;

    if (authForm.isLocalMode) {
      if (email.isEmpty) {
        emailError = l10n.text('auth.usernameRequired');
      }
    } else {
      if (email.isEmpty) {
        emailError = l10n.text('auth.emailRequired');
      } else if (!email.contains('@')) {
        emailError = l10n.text('auth.emailInvalid');
      }

      if (password.length < 6) {
        passwordError = l10n.text('auth.passwordMinLength');
      }
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authForm = ref.watch(authFormProvider);
    final title = authForm.isLocalMode
        ? l10n.text('auth.localTitle')
        : authForm.isLoginMode
        ? l10n.text('auth.loginTitle')
        : l10n.text('auth.registerTitle');

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
                        title: title,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppTextInput(
                              controller: _emailController,
                              label: authForm.isLocalMode
                                  ? l10n.text('auth.usernameLabel')
                                  : l10n.text('auth.emailLabel'),
                              placeholder: authForm.isLocalMode
                                  ? l10n.text('auth.usernamePlaceholder')
                                  : l10n.text('auth.emailPlaceholder'),
                              keyboardType: authForm.isLocalMode
                                  ? TextInputType.text
                                  : TextInputType.emailAddress,
                              textInputAction: authForm.isLocalMode
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              enableSuggestions: false,
                              errorText: _emailError,
                              onSubmitted: authForm.isLocalMode
                                  ? (_) => _submit()
                                  : null,
                              onChanged: (_) {
                                if (_emailError == null) {
                                  return;
                                }
                                setState(() {
                                  _emailError = null;
                                });
                              },
                            ),
                            if (!authForm.isLocalMode) ...[
                              const SizedBox(height: 12),
                              AppTextInput(
                                controller: _passwordController,
                                label: l10n.text('auth.passwordLabel'),
                                placeholder: l10n.text(
                                  'auth.passwordPlaceholder',
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                enableSuggestions: false,
                                errorText: _passwordError,
                                onSubmitted: (_) => _submit(),
                                onChanged: (_) {
                                  if (_passwordError == null) {
                                    return;
                                  }
                                  setState(() {
                                    _passwordError = null;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 32),
                            AppButton(
                              label: authForm.isSubmitting
                                  ? l10n.text('auth.pleaseWait')
                                  : title,
                              isLoading: authForm.isSubmitting,
                              onPressed: authForm.isSubmitting ? null : _submit,
                            ),
                            const SizedBox(height: 8),
                            if (!authForm.isLocalMode)
                              TextButton(
                                onPressed: authForm.isSubmitting
                                    ? null
                                    : () {
                                        ref
                                            .read(authFormProvider.notifier)
                                            .toggleMode();
                                      },
                                child: Text(
                                  authForm.isLoginMode
                                      ? l10n.text('auth.registerPrompt')
                                      : l10n.text('auth.loginPrompt'),
                                ),
                              ),
                            TextButton(
                              onPressed: authForm.isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _emailError = null;
                                        _passwordError = null;
                                      });
                                      ref
                                          .read(authFormProvider.notifier)
                                          .toggleLocalMode();
                                    },
                              child: Text(
                                authForm.isLocalMode
                                    ? l10n.text('auth.credentialsPrompt')
                                    : l10n.text('auth.localPrompt'),
                              ),
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
