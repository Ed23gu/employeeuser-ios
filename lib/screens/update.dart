import 'package:flutter/material.dart';

class PageNotifier extends ChangeNotifier {
  void updatePage() {
    notifyListeners();
  }
}
