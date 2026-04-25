import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/username_provider.dart';
import '../home/home_page.dart';
import 'auth_page.dart';
import 'auth_providers.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localUsername = ref.watch(usernameProvider);
    final authSession = ref.watch(authSessionProvider);

    return localUsername.when(
      data: (username) {
        if (username != null && username.isNotEmpty) {
          return const HomePage();
        }

        return authSession.when(
          data: (session) =>
              session == null ? const AuthPage() : const HomePage(),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const AuthPage(),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const AuthPage(),
    );
  }
}
