import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

/// Camada de persistência local usando SharedPreferences (suporta Web, Android, iOS)
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  // ─── User Keys ───────────────────────────────────────────
  static const _usersKey = 'cf_users';
  static const _userIdCounterKey = 'cf_user_id_counter';

  // ─── Helpers ──────────────────────────────────────────────
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(raw));
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await _prefs;
    await prefs.setString(_usersKey, json.encode(users));
  }

  // ─── User Methods ─────────────────────────────────────────
  Future<int> insertUser(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    final users = await _getUsers();

    // Check if email already exists
    final exists = users.any((u) => u['email'] == user['email']);
    if (exists) throw Exception('Email já cadastrado.');

    int counter = (prefs.getInt(_userIdCounterKey) ?? 0) + 1;
    await prefs.setInt(_userIdCounterKey, counter);

    final newUser = {...user, 'id': counter};
    users.add(newUser);
    await _saveUsers(users);
    return counter;
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final users = await _getUsers();
    try {
      return users.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Transaction Methods ──────────────────────────────────
  String _txKey(int userId) => 'cf_transactions_$userId';

  Future<List<Map<String, dynamic>>> _getRawTransactions(int userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_txKey(userId));
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(raw));
  }

  Future<void> _saveRawTransactions(int userId, List<Map<String, dynamic>> txs) async {
    final prefs = await _prefs;
    await prefs.setString(_txKey(userId), json.encode(txs));
  }

  Future<void> insertTransaction(TransactionItem transaction, int userId) async {
    final txs = await _getRawTransactions(userId);
    final map = transaction.toMap();
    map['userId'] = userId;
    // Remove if exists (upsert)
    txs.removeWhere((t) => t['id'] == map['id']);
    txs.insert(0, map);
    await _saveRawTransactions(userId, txs);
  }

  Future<void> deleteTransaction(String id) async {
    final prefs = await _prefs;
    final keys = prefs.getKeys().where((k) => k.startsWith('cf_transactions_'));
    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      final txs = List<Map<String, dynamic>>.from(json.decode(raw));
      final before = txs.length;
      txs.removeWhere((t) => t['id'] == id);
      if (txs.length != before) {
        await prefs.setString(key, json.encode(txs));
        return;
      }
    }
  }

  Future<List<TransactionItem>> getTransactions(int userId) async {
    final txs = await _getRawTransactions(userId);
    // Sort by date descending
    txs.sort((a, b) => b['date'].compareTo(a['date']));
    return txs.map((m) => TransactionItem.fromMap(m)).toList();
  }
}
