import 'package:flutter/foundation.dart';

class ScrollBus {
  static final ValueNotifier<int> homeTop = ValueNotifier(0);
  static final ValueNotifier<int> homeAfisha = ValueNotifier(0);
  static final ValueNotifier<int> newsTop = ValueNotifier(0);
  static final ValueNotifier<int> proposeTop = ValueNotifier(0);

  static void scrollTabToTop(int index) {
    if (index == 0) homeTop.value++;
    if (index == 1) newsTop.value++;
    if (index == 2) proposeTop.value++;
  }

  static void scrollToAfisha() {
    homeAfisha.value++;
  }
}
