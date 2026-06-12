import 'package:flutter/foundation.dart';

class CartProvider extends ChangeNotifier {
  int _itemCount = 0;
  int get itemCount => _itemCount;

  void update(int count) {
    if (_itemCount != count) {
      _itemCount = count;
      notifyListeners();
    }
  }

  void clear() {
    if (_itemCount != 0) {
      _itemCount = 0;
      notifyListeners();
    }
  }
}
