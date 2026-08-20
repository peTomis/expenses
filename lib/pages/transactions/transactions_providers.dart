import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Category uuid to pre-filter the Transactions tab by, set by whichever
/// screen navigates into it (Categories rows, the home ring legend) since
/// there's no router to pass navigation arguments through.
final transactionsFilterProvider =
    NotifierProvider<TransactionsFilterNotifier, String?>(
      TransactionsFilterNotifier.new,
    );

class TransactionsFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? categoryUuid) {
    state = categoryUuid;
  }
}
