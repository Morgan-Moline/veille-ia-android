import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/veille_article.dart';
import '../models/category.dart';
import '../widgets/category_artwork.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.article, required this.isFavorite, required this.onFavorite});
  final VeilleArticle article;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final category = veilleCategories.firstWhere((c) => c.name == article.category, orElse: () => veilleCategories.first);
    final date = article.publishedAt == null ? 'Date non disponible' : MaterialLocalizations.of(context).formatMediumDate(article.publishedAt!.toLocal());
    return Scaffold(
      appBar: AppBar(title: const Text('Article'), actions: [IconButton(onPressed: onFavorite, icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border, color: category.color))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        Container(height: 150, decoration: BoxDecoration(color: category.color.withOpacity(.08), borderRadius: BorderRadius.circular(22)), clipBehavior: Clip.antiAlias, child: Stack(fit: StackFit.expand, children: [
          CategoryArtwork(imageKey: category.imageKey, fit: BoxFit.cover),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [category.color.withOpacity(.92), category.color.withOpacity(.22)]))),
          Padding(padding: const EdgeInsets.all(20), child: Align(alignment: Alignment.bottomLeft, child: Text(category.shortName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2)))),
        ])),
        const SizedBox(height: 22),
        Text(article.source.toUpperCase(), style: TextStyle(color: category.color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.1)),
        const SizedBox(height: 8),
        Text(article.title, style: const TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF16324F))),
        const SizedBox(height: 12),
        Text('$date  •  ${category.shortName}', style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13)),
        if (article.summary.trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(children: [Icon(Icons.auto_awesome, color: category.color, size: 19), const SizedBox(width: 8), const Text('Résumé IA', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 10),
          Text(article.summary, style: const TextStyle(fontSize: 16, height: 1.55)),
        ],
        if (article.description.trim().isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text('À propos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(article.description, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 15, height: 1.5)),
        ],
        const SizedBox(height: 28),
        FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: category.color, minimumSize: const Size.fromHeight(52)), onPressed: () => launchUrl(Uri.parse(article.link), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new), label: const Text('Lire l’article complet')),
      ]),
    );
  }
}
