import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_helper.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final bool isLogin;
  final bool isLoading;
  final int? userId;
  final String? error;

  AuthState({
    this.isLogin = true,
    this.isLoading = false,
    this.userId,
    this.error,
  });

  AuthState copyWith({
    bool? isLogin,
    bool? isLoading,
    int? userId,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLogin: isLogin ?? this.isLogin,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkLoginStatus();
    return AuthState();
  }

  void toggleAuthMode() {
    state = state.copyWith(isLogin: !state.isLogin, clearError: true);
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      state = state.copyWith(userId: userId);
    }
  }

  Future<bool> authenticate(String email, String password, {String? name}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dbHelper = DBHelper();
      if (state.isLogin) {
        final user = await dbHelper.getUser(email, password);
        if (user != null) {
          final userId = user['id'] as int;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', userId);
          state = state.copyWith(isLoading: false, userId: userId);
          return true;
        } else {
          state = state.copyWith(isLoading: false, error: 'Credenciais inválidas.');
          return false;
        }
      } else {
        // Register
        final userId = await dbHelper.insertUser({
          'name': name ?? '',
          'email': email,
          'password': password,
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userId);
        state = state.copyWith(isLoading: false, userId: userId);
        return true;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao autenticar. Verifique seus dados.');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    state = AuthState(); // Reset state
  }
}
