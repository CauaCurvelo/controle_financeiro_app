import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLogin = true;
  bool get isLogin => _isLogin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void toggleAuthMode() {
    _isLogin = !_isLogin;
    notifyListeners();
  }

  Future<bool> authenticate(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    // Simula uma chamada de API
    await Future.delayed(const Duration(seconds: 1));
    
    _isLoading = false;
    notifyListeners();
    
    return true; // Sucesso no protótipo
  }
}
