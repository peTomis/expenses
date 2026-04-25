import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appPrimaryColorShadesProvider = Provider<AppPrimaryColorShades>((ref) {
  return const AppPrimaryColorShades(
    defaultColor: Color(0xFF001F2B),
    shade50: Color(0xFF8CE6FF),
    shade100: Color(0xFF00B8FF),
    shade200: Color(0xFF009BD6),
    shade300: Color(0xFF00719C),
    shade400: Color(0xFF00415A),
    shade500: Color(0xFF001F2B),
  );
});

class AppPrimaryColorShades {
  const AppPrimaryColorShades({
    required this.defaultColor,
    required this.shade50,
    required this.shade100,
    required this.shade200,
    required this.shade300,
    required this.shade400,
    required this.shade500,
  });

  final Color defaultColor;
  final Color shade50;
  final Color shade100;
  final Color shade200;
  final Color shade300;
  final Color shade400;
  final Color shade500;
}

final appPrimaryDefaultColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimaryColorShadesProvider).defaultColor;
});

final appPrimary50ColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimaryColorShadesProvider).shade50;
});

final appPrimary100ColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimaryColorShadesProvider).shade100;
});

final appPrimary200ColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimaryColorShadesProvider).shade200;
});

final appPrimary300ColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimaryColorShadesProvider).shade300;
});

final appPrimary400ColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimaryColorShadesProvider).shade400;
});

final appPrimary500ColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimaryColorShadesProvider).shade500;
});

final appBackgroundColorProvider = Provider<Color>((ref) {
  return ref.watch(appPrimary500ColorProvider);
});

final widgetBackgroundColorProvider = Provider<Color>((ref) {
  return const Color(0xFF000000);
});

final appPrimaryTextColorProvider = Provider<Color>((ref) {
  return const Color(0xFFCECECE);
});
