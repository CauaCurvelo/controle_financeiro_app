import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final newsProvider = FutureProvider<List<NewsItem>>((ref) async {
  // Simulating a financial news/tips API with a public API
  final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts?_limit=5'));
  
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => NewsItem.fromJson(json)).toList();
  } else {
    throw Exception('Falha ao carregar notícias financeiras');
  }
});

class NewsItem {
  final int id;
  final String title;
  final String body;

  NewsItem({required this.id, required this.title, required this.body});

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}
