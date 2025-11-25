import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinLockController extends ChangeNotifier {
  static const _pinKey = 'app_pin_code';

  String? _pin;
  bool _isLoading = true;

  PinLockController() {
    _loadPin();
  }

  bool get isLoading => _isLoading;
  bool get hasPin => _pin != null;

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    _pin = pin;
    notifyListeners();
  }

  bool verify(String input) {
    return _pin == input;
  }
}
