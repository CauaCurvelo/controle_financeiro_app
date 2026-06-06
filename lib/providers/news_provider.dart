import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketIndicator {
  final String name;
  final String code;
  final String value;
  final String variation;
  final bool isPositive;

  MarketIndicator({
    required this.name,
    required this.code,
    required this.value,
    required this.variation,
    required this.isPositive,
  });

  factory MarketIndicator.fromJson(Map<String, dynamic> json) {
    double pct = double.tryParse(json['pctChange'].toString()) ?? 0.0;
    return MarketIndicator(
      name: json['name'].toString().split('/')[0], // Extract only "Dólar Americano"
      code: json['code'],
      value: double.parse(json['bid']).toStringAsFixed(2),
      variation: '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
      isPositive: pct >= 0,
    );
  }
}

final marketProvider = FutureProvider<List<MarketIndicator>>((ref) async {
  final response = await http.get(Uri.parse('https://economia.awesomeapi.com.br/last/USD-BRL,EUR-BRL,BTC-BRL'));
  
  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    List<MarketIndicator> indicators = [];
    
    if (data.containsKey('USDBRL')) indicators.add(MarketIndicator.fromJson(data['USDBRL']));
    if (data.containsKey('EURBRL')) indicators.add(MarketIndicator.fromJson(data['EURBRL']));
    if (data.containsKey('BTCBRL')) indicators.add(MarketIndicator.fromJson(data['BTCBRL']));
    
    return indicators;
  } else {
    throw Exception('Falha ao carregar indicadores de mercado');
  }
});
