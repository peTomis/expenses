import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/button/app_button.dart';
import '../../components/card/app_card.dart';
import '../../components/text_input/app_text_input.dart';
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authForm = ref.read(authFormProvider);
    if (!_validateInputs() || authForm.isSubmitting) {
      return;
    }

    ref.read(authFormProvider.notifier).setSubmitting(true);

    final auth = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (authForm.isLoginMode) {
        await auth.signIn(email: email, password: password);
      } else {
        await auth.signUp(email: email, password: password);
      }

      if (!mounted) {
        return;
      }

      final message = authForm.isLoginMode
          ? 'Logged in successfully.'
          : 'Registered successfully. Check your email if confirmation is required.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
        const SnackBar(content: Text('Unexpected error. Please try again.')),
      );
    } finally {
      ref.read(authFormProvider.notifier).setSubmitting(false);
    }
  }

  bool _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailError;
    String? passwordError;

    if (email.isEmpty) {
      emailError = 'Email is required.';
    } else if (!email.contains('@')) {
      emailError = 'Enter a valid email.';
    }

    if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters.';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    return emailError == null && passwordError == null;
  }

  @override
  Widget build(BuildContext context) {
    final authForm = ref.watch(authFormProvider);
    final title = authForm.isLoginMode ? 'Login' : 'Register';

    return Scaffold(
      body: SafeArea(
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
                    Theme.of(context).colorScheme.primary,
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
                        label: 'Email',
                        placeholder: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: _emailError,
                        onChanged: (_) {
                          if (_emailError == null) {
                            return;
                          }
                          setState(() {
                            _emailError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextInput(
                        controller: _passwordController,
                        label: 'Password',
                        placeholder: '********',
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        errorText: _passwordError,
                        onChanged: (_) {
                          if (_passwordError == null) {
                            return;
                          }
                          setState(() {
                            _passwordError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: authForm.isSubmitting ? 'Please wait...' : title,
                        isLoading: authForm.isSubmitting,
                        onPressed: authForm.isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: 8),
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
                              ? 'Need an account? Register'
                              : 'Already have an account? Login',
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
    );
  }
}
