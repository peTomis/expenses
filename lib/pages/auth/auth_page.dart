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

  bool _isChoosingAccountType = true;
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
    final username = ref.read(usernameProvider.notifier);
    final authFormNotifier = ref.read(authFormProvider.notifier);

    try {
      if (authForm.isLocalMode) {
        await username.setUsername(email);
        return;
      }

      authFormNotifier.setSubmitting(true);

      final auth = ref.read(authRepositoryProvider);
      if (authForm.isLoginMode) {
        await auth.signIn(email: email, password: password);
        final usernameValue = auth.currentUser?.email ?? email;
        await username.setUsername(usernameValue);
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
        authFormNotifier.setSubmitting(false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context);
    final authForm = ref.read(authFormProvider);
    if (authForm.isSubmitting) {
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = l10n.text('auth.emailRequired');
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _emailError = l10n.text('auth.emailInvalid');
      });
      return;
    }

    final auth = ref.read(authRepositoryProvider);
    final authFormNotifier = ref.read(authFormProvider.notifier);

    try {
      authFormNotifier.setSubmitting(true);
      await auth.resetPassword(email: email);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('auth.resetPasswordSuccess'))),
      );
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
        authFormNotifier.setSubmitting(false);
      }
    }
  }

  void _clearFormErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  void _showChoice() {
    _clearFormErrors();
    ref.read(authFormProvider.notifier).reset();
    setState(() {
      _isChoosingAccountType = true;
    });
  }

  void _chooseOnlineAccount() {
    _clearFormErrors();
    ref.read(authFormProvider.notifier).reset();
    setState(() {
      _isChoosingAccountType = false;
    });
  }

  void _chooseLocalAccount() {
    _clearFormErrors();
    ref.read(authFormProvider.notifier).reset();
    ref.read(authFormProvider.notifier).toggleLocalMode();
    setState(() {
      _isChoosingAccountType = false;
    });
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
    final buttonText = authForm.isLocalMode
        ? l10n.text('auth.localButton')
        : authForm.isLoginMode
        ? l10n.text('auth.loginButton')
        : l10n.text('auth.registerButton');

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
                      if (_isChoosingAccountType)
                        _AccountChoiceCard(
                          onOnlineSelected: _chooseOnlineAccount,
                          onLocalSelected: _chooseLocalAccount,
                        )
                      else
                        AppCard(
                          title: title,
                          titleLeading: IconButton(
                            tooltip: l10n.text('auth.backToAccountChoice'),
                            visualDensity: VisualDensity.compact,
                            onPressed: authForm.isSubmitting
                                ? null
                                : _showChoice,
                            icon: const Icon(Icons.arrow_back),
                          ),
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
                                if (authForm.isLoginMode) ...[
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(0, 36),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: authForm.isSubmitting
                                          ? null
                                          : _forgotPassword,
                                      child: Text(
                                        l10n.text('auth.forgotPassword'),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                              SizedBox(
                                height:
                                    authForm.isLoginMode &&
                                        !authForm.isLocalMode
                                    ? 18
                                    : 28,
                              ),
                              AppButton(
                                label: authForm.isSubmitting
                                    ? l10n.text('auth.pleaseWait')
                                    : buttonText,
                                isLoading: authForm.isSubmitting,
                                onPressed: authForm.isSubmitting
                                    ? null
                                    : _submit,
                              ),
                              const SizedBox(height: 10),
                              if (!authForm.isLocalMode)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
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

class _AccountChoiceCard extends ConsumerWidget {
  const _AccountChoiceCard({
    required this.onOnlineSelected,
    required this.onLocalSelected,
  });

  final VoidCallback onOnlineSelected;
  final VoidCallback onLocalSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      title: l10n.text('auth.accountChoiceTitle'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _AccountChoiceTile(
              icon: Icons.cloud_outlined,
              title: l10n.text('auth.onlineAccountTitle'),
              subtitle: l10n.text('auth.onlineAccountDescription'),
              onTap: onOnlineSelected,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AccountChoiceTile(
              icon: Icons.folder_outlined,
              title: l10n.text('auth.localAccountTitle'),
              subtitle: l10n.text('auth.localAccountDescription'),
              onTap: onLocalSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountChoiceTile extends ConsumerWidget {
  const _AccountChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = ref.watch(appPrimaryTextColorProvider);
    final accentColor = ref.watch(appPrimary100ColorProvider);
    final borderColor = ref.watch(appPrimary300ColorProvider);
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
    );
    final descriptionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: textColor.withValues(alpha: 0.74),
      fontSize: 11,
      height: 1.2,
    );

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileSize = constraints.maxHeight;
          final padding = tileSize < 148 ? 10.0 : 12.0;
          final iconSize = (tileSize * 0.28).clamp(36.0, 48.0);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.55),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: accentColor, size: iconSize),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Center(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: descriptionStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
