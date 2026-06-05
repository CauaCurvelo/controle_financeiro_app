import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

/// Serviço que simula a integração com um Banco de Dados Externo (Firebase Realtime DB / REST API)
/// Trabalha em conjunto com o SQLite (Persistência Local).
class CloudSyncService {
  // URL de um banco de dados externo (Exemplo: Firebase Realtime Database)
  static const String _cloudDbUrl = 'https://controle-financeiro-cloud-default-rtdb.firebaseio.com/backups';

  /// Envia as transações locais para o banco de dados externo (Backup na Nuvem)
  static Future<bool> syncToCloud(int userId, List<TransactionItem> transactions) async {
    try {
      final url = Uri.parse('$_cloudDbUrl/$userId.json');
      
      final Map<String, dynamic> dataToSync = {
        'last_sync': DateTime.now().toIso8601String(),
        'transactions': transactions.map((tx) => tx.toMap()).toList(),
      };

      // Realiza o PUT para o banco externo (sobrescreve o backup anterior do usuário)
      final response = await http.put(
        url,
        body: json.encode(dataToSync),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true; // Sincronizado com sucesso
      }
      return false;
    } catch (e) {
      // Ignora erro de rede para não travar o app local (Offline First)
      return false; 
    }
  }
}
