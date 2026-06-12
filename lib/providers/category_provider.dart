import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryProvider =
    NotifierProvider<CategoryNotifier, List<FinancialCategory>>(
      CategoryNotifier.new,
    );

const defaultCategories = [
  FinancialCategory(
    uuid: 'c4f7a05b-b3f0-4613-9e8a-4be7d35d7e0c',
    name: 'Bar/Restaurant',
    icon: Icons.restaurant_outlined,
  ),
  FinancialCategory(
    uuid: 'c8500242-e52b-4b39-948d-1559b671d157',
    name: 'Bill',
    icon: Icons.receipt_long_outlined,
  ),
  FinancialCategory(
    uuid: '9c8f7164-6af0-4310-b7e1-c26676eadf20',
    name: 'Bureaucracy',
    icon: Icons.account_balance_outlined,
  ),
  FinancialCategory(
    uuid: '28ab1c89-088a-4214-a831-c50fb915a5f0',
    name: 'Grocery',
    icon: Icons.local_grocery_store_outlined,
  ),
  FinancialCategory(
    uuid: 'fd682f89-89d6-47d5-a6e4-e628df0f5c0a',
    name: 'House',
    icon: Icons.home_outlined,
  ),
  FinancialCategory(
    uuid: '2574f7a3-68f9-4567-9340-6e0a6d6bf6c2',
    name: 'Loan',
    icon: Icons.request_quote_outlined,
  ),
  FinancialCategory(
    uuid: 'cddbf4f2-43c0-4785-a57f-20f895a284f1',
    name: 'Operation',
    icon: Icons.sync_alt_outlined,
  ),
  FinancialCategory(
    uuid: 'f1e9381f-94e4-49fa-94c9-5d28a5c09f6b',
    name: 'Salary',
    icon: Icons.work_outline,
  ),
  FinancialCategory(
    uuid: 'a6ac97a9-808e-46ba-a220-d42bb2f0a8c2',
    name: 'Saving',
    icon: Icons.savings_outlined,
  ),
  FinancialCategory(
    uuid: '5f731849-955c-4eb1-a0dd-9dcd67f3196a',
    name: 'Software',
    icon: Icons.apps_outlined,
  ),
  FinancialCategory(
    uuid: 'bb68251e-5f8d-4e06-9554-431c83d4f8f7',
    name: 'Tech',
    icon: Icons.devices_outlined,
  ),
  FinancialCategory(
    uuid: '808ee51b-e0dc-4a7f-8ff7-c5a236f23fac',
    name: 'Travel & Fun',
    icon: Icons.flight_takeoff_outlined,
  ),
];

const categoryIconByName = {
  'bar/restaurant': Icons.restaurant_outlined,
  'bill': Icons.receipt_long_outlined,
  'bureaucracy': Icons.account_balance_outlined,
  'clothing': Icons.checkroom_outlined,
  'collection': Icons.collections_bookmark_outlined,
  'dog': Icons.pets_outlined,
  'gas': Icons.local_gas_station_outlined,
  'gift': Icons.card_giftcard_outlined,
  'grocery': Icons.local_grocery_store_outlined,
  'house': Icons.home_outlined,
  'loan': Icons.request_quote_outlined,
  'operation': Icons.sync_alt_outlined,
  'salary': Icons.work_outline,
  'saving': Icons.savings_outlined,
  'software': Icons.apps_outlined,
  'tech': Icons.devices_outlined,
  'travel & fun': Icons.flight_takeoff_outlined,
  'video provider': Icons.live_tv_outlined,
  'videogame': Icons.sports_esports_outlined,
};

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

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'icon': {
        'codePoint': icon.codePoint,
        'fontFamily': icon.fontFamily,
        'fontPackage': icon.fontPackage,
        'matchTextDirection': icon.matchTextDirection,
      },
    };
  }

  static FinancialCategory? fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid'] as String?;
    final name = json['name'] as String?;
    final iconJson = json['icon'] as Map<String, dynamic>?;
    final codePoint = iconJson?['codePoint'] as int?;

    if (uuid == null || name == null || codePoint == null) {
      return null;
    }

    return FinancialCategory(
      uuid: uuid,
      name: name,
      icon: IconData(
        codePoint,
        fontFamily: iconJson?['fontFamily'] as String?,
        fontPackage: iconJson?['fontPackage'] as String?,
        matchTextDirection: iconJson?['matchTextDirection'] as bool? ?? false,
      ),
    );
  }
}

class CategoryNotifier extends Notifier<List<FinancialCategory>> {
  final _random = Random.secure();

  @override
  List<FinancialCategory> build() {
    return _sortCategories(defaultCategories);
  }

  void addCategory({required String name, IconData? icon}) {
    final trimmedName = name.trim();
    final category = FinancialCategory(
      uuid: _uuidV4(),
      name: trimmedName,
      icon: icon ?? iconForCategoryName(trimmedName),
    );

    state = _sortCategories([...state, category]);
  }

  IconData iconForCategoryName(String name) {
    return categoryIconByName[name.trim().toLowerCase()] ?? Icons.label_outline;
  }

  void updateCategory(FinancialCategory category) {
    state = _sortCategories([
      for (final existingCategory in state)
        existingCategory.uuid == category.uuid ? category : existingCategory,
    ]);
  }

  void removeCategory(String uuid) {
    if (state.length <= 1) {
      return;
    }

    state = _sortCategories([
      for (final category in state)
        if (category.uuid != uuid) category,
    ]);
  }

  void replaceCategories(List<FinancialCategory> categories) {
    if (categories.isEmpty) {
      return;
    }

    state = _sortCategories(categories);
  }

  List<FinancialCategory> _sortCategories(List<FinancialCategory> categories) {
    return [...categories]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
