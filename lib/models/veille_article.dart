class VeilleArticle {
  const VeilleArticle({
    required this.title,
    required this.link,
    required this.description,
    required this.source,
    required this.category,
    this.publishedAt,
    this.summary = '',
  });

  final String title;
  final String link;
  final String description;
  final String source;
  final String category;
  final DateTime? publishedAt;
  final String summary;

  factory VeilleArticle.fromJson(Map<String, dynamic> json) => VeilleArticle(
    title: _clean(json['title']),
    link: (json['link'] ?? '').toString().trim(),
    description: _clean(json['description']),
    source: (json['source'] ?? 'Source inconnue').toString(),
    category: (json['category'] ?? 'Autre').toString(),
    publishedAt: DateTime.tryParse((json['published_at'] ?? '').toString()),
    summary: _clean(json['summary']),
  );

  static String _clean(dynamic value) => (value ?? '').toString()
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"').replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\\s+'), ' ').trim();
}
