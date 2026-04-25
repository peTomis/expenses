import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(
  HomeTabIndexNotifier.new,
);

class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 1;
  }

  void setIndex(int index) {
    state = index;
  }
}
