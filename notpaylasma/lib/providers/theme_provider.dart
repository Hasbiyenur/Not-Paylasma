import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({String initial = 'system', this.save})
    : _mode = ThemeMode.values.byName(initial);
  final Future<void> Function(String)? save;
  ThemeMode _mode;
  bool busy = false;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode value) async {
    if (_mode == value || busy) return;
    busy = true;
    notifyListeners();
    try {
      await save?.call(value.name);
      _mode = value;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
