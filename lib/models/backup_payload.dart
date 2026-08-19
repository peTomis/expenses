import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/category_provider.dart';
import '../providers/financial_data_provider.dart';
import '../providers/last_mutation_provider.dart';

/// Everything that needs to be backed up / synced, bundled together so
/// manual export/import and Google Drive sync share one "gather local
/// state into JSON" / "apply JSON to local state" implementation.
class BackupPayload {
  const BackupPayload({
    required this.version,
    required this.updatedAt,
    required this.financialData,
    required this.categories,
  });

  static const currentVersion = 1;

  final int version;

  /// When the local data was last mutated by the user — not when this
  /// payload was exported/synced. Used for last-write-wins comparisons.
  final DateTime updatedAt;
  final FinancialDataState financialData;
  final List<FinancialCategory> categories;

  factory BackupPayload.fromProviders(Ref ref) {
    return BackupPayload(
      version: currentVersion,
      updatedAt: ref.read(lastMutationProvider),
      financialData: ref.read(financialDataProvider),
      categories: ref.read(categoryProvider),
    );
  }

  /// Applies this payload to local state, mirroring the `updatedAt` it
  /// carried rather than stamping "now" — otherwise applying remote data
  /// would immediately make local look newer than what was just applied.
  void applyToProviders(Ref ref) {
    ref.read(financialDataProvider.notifier).replaceAll(financialData);
    ref.read(categoryProvider.notifier).replaceCategories(categories);
    ref.read(lastMutationProvider.notifier).setExactly(updatedAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'financialData': financialData.toJson(),
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }

  static BackupPayload? fromJson(Map<String, dynamic> json) {
    final updatedAtString = json['updatedAt'] as String?;
    final updatedAt = updatedAtString == null
        ? null
        : DateTime.tryParse(updatedAtString);
    final financialDataJson = json['financialData'];
    final categoriesJson = json['categories'];
    if (updatedAt == null ||
        financialDataJson is! Map ||
        categoriesJson is! List) {
      return null;
    }

    final financialData = FinancialDataState.fromJson(
      Map<String, dynamic>.from(financialDataJson),
    );
    if (financialData == null) {
      return null;
    }

    final categories = <FinancialCategory>[];
    for (final item in categoriesJson) {
      final category = switch (item) {
        final Map<String, dynamic> json => FinancialCategory.fromJson(json),
        final Map json => FinancialCategory.fromJson(
          Map<String, dynamic>.from(json),
        ),
        _ => null,
      };
      if (category != null) {
        categories.add(category);
      }
    }

    if (categories.isEmpty) {
      return null;
    }

    return BackupPayload(
      version: (json['version'] as int?) ?? currentVersion,
      updatedAt: updatedAt,
      financialData: financialData,
      categories: categories,
    );
  }
}
