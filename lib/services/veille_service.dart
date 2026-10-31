import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/veille_article.dart';

class VeilleService {
  static const dataUrl = 'https://raw.githubusercontent.com/Morgan-Moline/veille-ia-data/main/data.json';
  static const triggerUrl = 'https://veille-ia-trigger.themomo450.workers.dev/';

  static Future<Map<String, dynamic>> fetchData() async {
    final uri = Uri.parse('$dataUrl?refresh=${DateTime.now().millisecondsSinceEpoch}');
    final response = await http.get(uri, headers: {'Cache-Control': 'no-cache'}).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) throw Exception('GitHub a répondu ${response.statusCode}');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> || decoded['articles'] is! List) {
      throw const FormatException('Le fichier de veille est invalide.');
    }
    return decoded;
  }

  static Future<List<VeilleArticle>> fetchArticles() async {
    final data = await fetchData();
    final unique = <String, VeilleArticle>{};
    for (final raw in data['articles'] as List) {
      if (raw is! Map) continue;
      final article = VeilleArticle.fromJson(Map<String, dynamic>.from(raw));
      if (article.link.isNotEmpty) unique[article.link] = article;
    }
    final articles = unique.values.toList()
      ..sort((a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
    return articles;
  }

  static Future<void> trigger(String secret) async {
    final response = await http.post(
      Uri.parse(triggerUrl),
      headers: {'Authorization': 'Bearer $secret', 'Content-Type': 'application/json'},
      body: '{}',
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) throw Exception('Secret incorrect.');
    if (response.statusCode != 202) throw Exception('Le lancement a échoué (${response.statusCode}).');
  }
}
