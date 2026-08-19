import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expenses/providers/category_provider.dart';
import 'package:expenses/providers/shared_preferences_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
  });

  test('build falls back to the default categories, sorted by name', () {
    final categories = container.read(categoryProvider);

    expect(categories, isNotEmpty);
    final names = categories.map((category) => category.name).toList();
    expect(names, [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())));
    expect(names.toSet(), defaultCategories.map((c) => c.name).toSet());
  });

  test('addCategory inserts a sorted, persisted category', () async {
    container
        .read(categoryProvider.notifier)
        .addCategory(name: 'Zzz Custom');

    final categories = container.read(categoryProvider);
    expect(categories.last.name, 'Zzz Custom');

    await Future<void>.delayed(Duration.zero);
    final preferences = container.read(sharedPreferencesProvider);
    expect(preferences.getString('categories'), isNotNull);
  });

  test('a persisted category list is restored on the next build', () async {
    container.read(categoryProvider.notifier).addCategory(name: 'Custom One');
    await Future<void>.delayed(Duration.zero);

    final preferences = container.read(sharedPreferencesProvider);
    final restoredContainer = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(restoredContainer.dispose);

    final restoredCategories = restoredContainer.read(categoryProvider);
    expect(
      restoredCategories.map((category) => category.name),
      contains('Custom One'),
    );
  });

  test('removeCategory refuses to drop the last remaining category', () {
    final notifier = container.read(categoryProvider.notifier);
    for (final category in [...container.read(categoryProvider)].skip(1)) {
      notifier.removeCategory(category.uuid);
    }

    final remaining = container.read(categoryProvider);
    expect(remaining, hasLength(1));

    notifier.removeCategory(remaining.single.uuid);
    expect(container.read(categoryProvider), hasLength(1));
  });

  test('replaceCategories ignores an empty list', () {
    final before = container.read(categoryProvider);
    container.read(categoryProvider.notifier).replaceCategories([]);
    expect(container.read(categoryProvider), equals(before));
  });

  test('iconForCategoryName matches known keywords case-insensitively', () {
    final notifier = container.read(categoryProvider.notifier);

    expect(
      notifier.iconForCategoryName('Weekly Grocery run'),
      Icons.local_grocery_store_outlined,
    );
    expect(
      notifier.iconForCategoryName('Something unrelated'),
      Icons.label_outline,
    );
  });
}
