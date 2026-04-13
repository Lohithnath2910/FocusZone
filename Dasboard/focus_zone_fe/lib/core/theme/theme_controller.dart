import 'package:flutter/material.dart';
import 'dart:async';

import '../../services/storage_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({double initialValue = 1.0})
    : value = initialValue.clamp(0.0, 1.0);

  double value;

  bool get isDark => value > 0.5;

  void setDark(bool dark) {
    update(dark ? 1.0 : 0.0);
  }

  void update(double v) {
    value = v.clamp(0.0, 1.0);
    notifyListeners();
    unawaited(StorageService.saveThemeValue(value));
  }
}
