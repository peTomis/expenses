import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryProvider =
    NotifierProvider<CategoryNotifier, List<FinancialCategory>>(
      CategoryNotifier.new,
    );

const defaultCategories = [
  FinancialCategory(
    uuid: 'f1e9381f-94e4-49fa-94c9-5d28a5c09f6b',
    name: 'Salary',
    icon: Icons.work_outline,
  ),
  FinancialCategory(
    uuid: '32c030a4-7376-4324-9766-f4c9b1b69767',
    name: 'Home',
    icon: Icons.home_outlined,
  ),
  FinancialCategory(
    uuid: '2302df73-25ef-491d-bb08-7e04b9ab9127',
    name: 'Food',
    icon: Icons.restaurant_outlined,
  ),
  FinancialCategory(
    uuid: '808ee51b-e0dc-4a7f-8ff7-c5a236f23fac',
    name: 'Transport',
    icon: Icons.train_outlined,
  ),
  FinancialCategory(
    uuid: '7308e47c-62db-467f-8010-bdb3d2b80fb8',
    name: 'Other',
    icon: Icons.category_outlined,
  ),
];

class FinancialCategory {
  const FinancialCategory({
    required this.uuid,
    required this.name,
    required this.icon,
  });

  final String uuid;
  final String name;
  final IconData icon;

  String get label => name;

  FinancialCategory copyWith({String? uuid, String? name, IconData? icon}) {
    return FinancialCategory(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}

class CategoryNotifier extends Notifier<List<FinancialCategory>> {
  final _random = Random.secure();

  @override
  List<FinancialCategory> build() {
    return defaultCategories;
  }

  void addCategory({
    required String name,
    IconData icon = Icons.label_outline,
  }) {
    final category = FinancialCategory(
      uuid: _uuidV4(),
      name: name.trim(),
      icon: icon,
    );

    state = [...state, category];
  }

  void updateCategory(FinancialCategory category) {
    state = [
      for (final existingCategory in state)
        existingCategory.uuid == category.uuid ? category : existingCategory,
    ];
  }

  void removeCategory(String uuid) {
    if (state.length <= 1) {
      return;
    }

    state = [
      for (final category in state)
        if (category.uuid != uuid) category,
    ];
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }
}
