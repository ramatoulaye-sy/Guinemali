import 'package:flutter/foundation.dart';

class RouterRefresh extends ChangeNotifier {
  RouterRefresh._();
  static final RouterRefresh instance = RouterRefresh._();

  void ping() {
    notifyListeners();
  }
}
