import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veille_ia/models/veille_article.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('article JSON is normalized and parsed', () {
    final article = VeilleArticle.fromJson({
      'title': '<b>Actualité</b> &amp; fiscalité',
      'link': 'https://example.com/article',
      'description': 'Description',
      'source': 'Source',
      'category': 'Comptabilité & fiscalité',
      'published_at': '2026-10-31T08:00:00Z',
      'summary': 'Résumé IA',
    });
    expect(article.title, 'Actualité & fiscalité');
    expect(article.link, 'https://example.com/article');
    expect(article.summary, 'Résumé IA');
    expect(article.category, 'Comptabilité & fiscalité');
  });

  test('BTS question bank contains 500 questions in 10 topics', () async {
    final raw = await rootBundle.loadString('assets/data/question_bank.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final topics = data['topics'] as Map<String, dynamic>;
    final count = topics.values.fold<int>(0, (total, questions) => total + (questions as List).length);
    expect(topics.length, 10);
    expect(count, 500);
  });

  test('category images are bundled locally', () async {
    for (final name in ['comptabilite', 'etudes', 'secteur_pro']) {
      final raw = await rootBundle.loadString('assets/data/category_$name.txt');
      expect(raw.length, greaterThan(1000));
    }
  });
}
