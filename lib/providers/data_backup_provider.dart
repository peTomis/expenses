import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'category_provider.dart';

final dataBackupControllerProvider =
    NotifierProvider<DataBackupController, DataBackupState>(
      DataBackupController.new,
    );

enum DataBackupStatus { idle, working, done, failed }

class DataBackupState {
  const DataBackupState({
    required this.status,
    this.lastBackupAt,
    this.message,
  });

  const DataBackupState.idle()
    : status = DataBackupStatus.idle,
      lastBackupAt = null,
      message = null;

  final DataBackupStatus status;
  final DateTime? lastBackupAt;
  final String? message;

  bool get isWorking => status == DataBackupStatus.working;
}

class DataBackupController extends Notifier<DataBackupState> {
  static const _lastBackupKey = 'categoriesLastBackupAt';

  @override
  DataBackupState build() {
    _restoreLastBackup();
    return const DataBackupState.idle();
  }

  Future<void> _restoreLastBackup() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_lastBackupKey);
    final lastBackup = value == null ? null : DateTime.tryParse(value);
    if (lastBackup == null || state.lastBackupAt != null) {
      return;
    }

    state = DataBackupState(
      status: DataBackupStatus.done,
      lastBackupAt: lastBackup,
    );
  }

  Future<bool> exportBackup() async {
    if (state.isWorking) {
      return false;
    }

    state = DataBackupState(
      status: DataBackupStatus.working,
      lastBackupAt: state.lastBackupAt,
    );

    try {
      final categories = ref.read(categoryProvider);
      final exportedAt = DateTime.now();
      final jsonString = jsonEncode({
        'categories': categories
            .map((category) => category.toJson())
            .toList(),
        'exportedAt': exportedAt.toUtc().toIso8601String(),
      });
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final fileName =
          'expenses-backup-${exportedAt.toUtc().toIso8601String().split('T').first}.json';

      final path = await FilePicker.saveFile(
        dialogTitle: 'Save expenses backup',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (path == null && !kIsWeb) {
        state = DataBackupState(
          status: DataBackupStatus.idle,
          lastBackupAt: state.lastBackupAt,
        );
        return false;
      }

      state = DataBackupState(
        status: DataBackupStatus.done,
        lastBackupAt: exportedAt,
      );
      await _persistLastBackup(exportedAt);
      return true;
    } catch (_) {
      state = DataBackupState(
        status: DataBackupStatus.failed,
        lastBackupAt: state.lastBackupAt,
        message: 'Export failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> importBackup() async {
    if (state.isWorking) {
      return false;
    }

    state = DataBackupState(
      status: DataBackupStatus.working,
      lastBackupAt: state.lastBackupAt,
    );

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      final pickedFile = result != null && result.files.isNotEmpty
          ? result.files.first
          : null;

      if (pickedFile == null) {
        state = DataBackupState(
          status: DataBackupStatus.idle,
          lastBackupAt: state.lastBackupAt,
        );
        return false;
      }

      var bytes = pickedFile.bytes;
      final path = pickedFile.path;
      if (bytes == null && path != null) {
        bytes = await File(path).readAsBytes();
      }

      if (bytes == null) {
        throw const FormatException('Could not read the selected file.');
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      final categoriesJson = decoded is Map ? decoded['categories'] : null;
      if (categoriesJson is! List) {
        throw const FormatException('Backup file is missing categories.');
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
        throw const FormatException('Backup file has no valid categories.');
      }

      ref.read(categoryProvider.notifier).replaceCategories(categories);

      final importedAt = DateTime.now();
      state = DataBackupState(
        status: DataBackupStatus.done,
        lastBackupAt: importedAt,
      );
      await _persistLastBackup(importedAt);
      return true;
    } catch (_) {
      state = DataBackupState(
        status: DataBackupStatus.failed,
        lastBackupAt: state.lastBackupAt,
        message: 'Import failed. Please choose a valid backup file.',
      );
      return false;
    }
  }

  Future<void> _persistLastBackup(DateTime dateTime) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastBackupKey, dateTime.toIso8601String());
  }
}
