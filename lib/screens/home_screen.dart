import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/veille_article.dart';
import '../services/veille_service.dart';
import '../widgets/category_artwork.dart';
import 'article_detail_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<VeilleArticle> _articles = [];
  Set<String> _favorites = {};
  Set<String> _read = {};
  int _tab = 0;
  String _category = 'Toutes';
  String _filter = 'Tous';
  String _search = '';
  bool _loading = true;
  bool _ascending = false;
  bool _watchRunning = false;
  String? _message;
  DateTime? _updatedAt;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh(silent: true);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favorites = (prefs.getStringList('veille-favorites') ?? []).toSet();
      _read = (prefs.getStringList('veille-read') ?? []).toSet();
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('veille-favorites', _favorites.toList());
    await prefs.setStringList('veille-read', _read.toList());
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && _articles.isEmpty && mounted) setState(() => _loading = true);
    try {
      final data = await VeilleService.fetchData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('veille-cache-data', jsonEncode(data));
      _applyData(data);
    } catch (_) {
      // Si le réseau est indisponible, on conserve l'accès aux derniers articles téléchargés.
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('veille-cache-data');
        if (cached != null) {
          _applyData(jsonDecode(cached) as Map<String, dynamic>, offline: true);
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_articles.isEmpty) _message = 'Impossible de récupérer les actualités. Vérifie ta connexion puis réessaie.';
      });
    }
  }

  void _applyData(Map<String, dynamic> data, {bool offline = false}) {
    final raw = data['articles'];
    if (raw is! List) throw const FormatException('Liste d’articles absente.');
    final unique = <String, VeilleArticle>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final article = VeilleArticle.fromJson(Map<String, dynamic>.from(item));
      if (article.link.isNotEmpty) unique[article.link] = article;
    }
    final result = unique.values.toList()
      ..sort((a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
    if (!mounted) return;
    setState(() {
      _articles = result;
      _updatedAt = DateTime.tryParse((data['updated_at'] ?? '').toString());
      _message = offline ? 'Mode hors connexion : derniers articles enregistrés.' : null;
      _loading = false;
    });
  }

  void _toggleFavorite(VeilleArticle article) {
    setState(() {
      if (_favorites.contains(article.link)) {
        _favorites.remove(article.link);
      } else {
        _favorites.add(article.link);
      }
    });
    _savePreferences();
  }

  Future<void> _openArticle(VeilleArticle article) async {
    if (!_read.contains(article.link)) {
      _read.add(article.link);
      _savePreferences();
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticleDetailScreen(
      article: article,
      isFavorite: _favorites.contains(article.link),
      onFavorite: () => _toggleFavorite(article),
    )));
    if (mounted) setState(() {});
  }

  Future<void> _askForNewWatch() async {
    final controller = TextEditingController();
    final secret = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lancer une nouvelle veille'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Le traitement sera effectué par Cloudflare. Tu pourras continuer à utiliser l’application pendant la génération.'),
          const SizedBox(height: 16),
          TextField(controller: controller, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Secret d’accès', hintText: 'APP_SECRET')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Lancer')),
        ],
      ),
    );
    controller.dispose();
    if (secret == null || secret.isEmpty || !mounted) return;
    setState(() { _watchRunning = true; _message = 'Envoi de la demande…'; });
    try {
      final before = _updatedAt;
      await VeilleService.trigger(secret);
      if (!mounted) return;
      setState(() => _message = 'Veille lancée en arrière-plan. Tu peux continuer à utiliser l’application.');
      // Le Worker Cloudflare continue même si l'application est fermée.
      // Cette boucle ne bloque pas l'interface : elle ne fait que vérifier l'arrivée des données.
      unawaited(_watchForNewData(before));
    } catch (e) {
      if (mounted) setState(() { _watchRunning = false; _message = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _watchForNewData(DateTime? before) async {
    final deadline = DateTime.now().add(const Duration(minutes: 8));
    var changed = false;
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(seconds: 10));
      try {
        final data = await VeilleService.fetchData();
        final next = DateTime.tryParse((data['updated_at'] ?? '').toString());
        if (next != null && (before == null || next.isAfter(before))) { changed = true; break; }
      } catch (_) {}
    }
    if (!mounted) return;
    if (changed) {
      await _refresh(silent: true);
      if (mounted) setState(() { _watchRunning = false; _message = 'Nouvelle veille récupérée !'; });
    } else {
      setState(() { _watchRunning = false; _message = 'Le traitement peut continuer côté serveur. Actualise les articles un peu plus tard.'; });
    }
  }

  List<VeilleArticle> get _visibleArticles {
    final query = _search.toLowerCase().trim();
    final list = _articles.where((a) {
      final categoryOk = _category == 'Toutes' || a.category == _category;
      final filterOk = _filter == 'Favoris'
        ? _favorites.contains(a.link)
        : _filter == 'Non lus' ? !_read.contains(a.link)
        : _filter == 'Lus' ? _read.contains(a.link) : true;
      final searchOk = query.isEmpty || [a.title, a.description, a.summary, a.source, a.category].join(' ').toLowerCase().contains(query);
      return categoryOk && filterOk && searchOk;
    }).toList();
    list.sort((a, b) {
      final compare = (a.publishedAt ?? DateTime(2000)).compareTo(b.publishedAt ?? DateTime(2000));
      return _ascending ? compare : -compare;
    });
    return list;
  }

  VeilleCategory _categoryFor(String name) {
    for (final category in veilleCategories) {
      if (category.name == name) return category;
    }
    return veilleCategories.first;
  }
  String _dateLabel(DateTime? date) {
    if (date == null) return 'Date non disponible';
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildNewsPage(),
      _buildNewsPage(favoritesOnly: true),
      const QuizScreen(),
      _buildSettingsPage(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.newspaper_outlined), selectedIcon: Icon(Icons.newspaper), label: 'Actualités'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Favoris'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Révisions'),
          NavigationDestination(icon: Icon(Icons.tune), selectedIcon: Icon(Icons.tune), label: 'Réglages'),
        ],
      ),
    );
  }

  Widget _buildNewsPage({bool favoritesOnly = false}) {
    final articles = favoritesOnly ? _visibleArticles.where((a) => _favorites.contains(a.link)).toList() : _visibleArticles;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 8), child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF16324F), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_awesome, color: Colors.white)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('VEILLE IA', style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Color(0xFF64809B))),
          Text('Ta veille, au bon endroit', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF16324F))),
        ])),
        IconButton(onPressed: _loading ? null : () => _refresh(), icon: const Icon(Icons.refresh_rounded)),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: _buildHero())),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Row(children: [
        Expanded(child: _statCard('Non lus', _articles.where((a) => !_read.contains(a.link)).length.toString(), Icons.mark_email_unread_outlined, const Color(0xFF2468B4))),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Favoris', _favorites.length.toString(), Icons.bookmark_border, const Color(0xFFF28C28))),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(hintText: 'Rechercher un article…', prefixIcon: const Icon(Icons.search), suffixIcon: _search.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() => _search = ''); }, icon: const Icon(Icons.close))),
      ))),
      SliverToBoxAdapter(child: SizedBox(height: 64, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(20, 14, 20, 8), children: [
        _categoryChip('Toutes', const Color(0xFF16324F)),
        ...veilleCategories.map((c) => _categoryChip(c.name, c.color)),
      ]))),
      if (!favoritesOnly) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 2, 20, 10), child: Wrap(spacing: 8, children: [
        for (final f in ['Tous', 'Non lus', 'Favoris', 'Lus'])
          ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() { _filter = f; _tab = 0; })),
        ActionChip(avatar: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16), label: const Text('Date'), onPressed: () => setState(() => _ascending = !_ascending)),
      ]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 8), child: Row(children: [
        Text(favoritesOnly ? 'MES FAVORIS' : '${articles.length} ARTICLES', style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: Color(0xFF7890A5))),
        const Spacer(),
        if (_updatedAt != null) Text('MAJ ${_dateLabel(_updatedAt)}', style: const TextStyle(fontSize: 10, color: Color(0xFF8A9BAA))),
      ]))),
      if (_loading && _articles.isEmpty) const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      if (_message != null && _articles.isEmpty) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24), child: Text(_message!, textAlign: TextAlign.center))),
      if (articles.isEmpty && !_loading && _articles.isNotEmpty) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(28), child: Center(child: Text(favoritesOnly ? 'Aucun favori pour le moment.' : 'Aucun article ne correspond à ta recherche.')))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
        final article = articles[index];
        return _articleCard(article);
      }, childCount: articles.length))),
    ]);
  }

  Widget _buildHero() {
    final selected = _category == 'Toutes' ? null : _categoryFor(_category);
    final color = selected?.color ?? const Color(0xFF16324F);
    final images = selected == null ? veilleCategories : [selected];
    return Container(height: 142, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)), clipBehavior: Clip.antiAlias, child: Stack(children: [
      Positioned.fill(child: Row(children: images.map((c) => Expanded(child: CategoryArtwork(imageKey: c.imageKey, fit: BoxFit.cover))).toList())),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(.94), color.withOpacity(.55), color.withOpacity(.18)])))),
      Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(selected?.eyebrow ?? 'COMPTABILITÉ • ÉTUDES • SECTEUR PRO', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(selected?.description ?? 'L’essentiel de tes actualités,\nréuni au même endroit.', style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.2, fontWeight: FontWeight.w800)),
      ])),
    ]));
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
    child: Row(children: [
      Icon(icon, color: color, size: 19),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF16324F))),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7890A5))),
      ])),
    ]),
  );

  Widget _categoryChip(String label, Color color) {
    final selected = _category == label;
    return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
      label: Text(label == 'Toutes' ? label : _categoryFor(label).shortName),
      selected: selected,
      selectedColor: color.withOpacity(.14),
      side: BorderSide(color: selected ? color : Colors.transparent),
      onSelected: (_) => setState(() => _category = label),
      labelStyle: TextStyle(color: selected ? color : const Color(0xFF60758A), fontWeight: FontWeight.w700),
    ));
  }

  Widget _articleCard(VeilleArticle article) {
    final category = _categoryFor(article.category);
    final isRead = _read.contains(article.link);
    final favorite = _favorites.contains(article.link);
    return Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openArticle(article),
      child: Padding(padding: const EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 5, height: 116, decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: category.color.withOpacity(.1), borderRadius: BorderRadius.circular(8)), child: Text(category.shortName, style: TextStyle(color: category.color, fontSize: 10, fontWeight: FontWeight.w800))),
            const Spacer(),
            if (isRead) const Icon(Icons.check_circle, color: Color(0xFF9AAAB8), size: 15),
            IconButton(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 34, minHeight: 34), onPressed: () => _toggleFavorite(article), icon: Icon(favorite ? Icons.bookmark : Icons.bookmark_border, color: favorite ? category.color : Colors.blueGrey)),
          ]),
          const SizedBox(height: 4),
          Text(article.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, height: 1.25, fontWeight: FontWeight.w800, color: isRead ? const Color(0xFF778899) : const Color(0xFF16324F))),
          const SizedBox(height: 8),
          if (article.summary.isNotEmpty)
            Text(article.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.35, color: Colors.blueGrey.shade600))
          else ...[
            Text(article.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.35, color: Colors.blueGrey.shade600)),
            const SizedBox(height: 5),
            const Row(children: [Icon(Icons.auto_awesome, size: 12, color: Color(0xFF9AAABD)), SizedBox(width: 5), Text('Résumé IA en attente', style: TextStyle(fontSize: 10, color: Color(0xFF9AAABD), fontWeight: FontWeight.w600))]),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(article.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8496A7)))),
            Text(_dateLabel(article.publishedAt), style: const TextStyle(fontSize: 10, color: Color(0xFF8496A7))),
          ]),
        ])),
      ])),
    ));
  }

  Widget _buildSettingsPage() => ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 30), children: [
    const Text('Réglages', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Color(0xFF16324F))),
    const SizedBox(height: 6),
    const Text('Automatisation et préférences', style: TextStyle(color: Color(0xFF7890A5))),
    const SizedBox(height: 22),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF2468B4)), SizedBox(width: 10), Text('Automatisation de la veille', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 10),
      const Text('Déclenche la collecte via Cloudflare. La génération continue côté serveur et ne bloque pas l’application.'),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _watchRunning ? null : _askForNewWatch, icon: const Icon(Icons.play_arrow), label: Text(_watchRunning ? 'Veille en cours…' : 'Lancer une nouvelle veille'))),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: const TextStyle(color: Color(0xFF2468B4), fontWeight: FontWeight.w600))),
    ]))),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Données partagées', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Les articles proviennent du dépôt central veille-ia-data. Les favoris et lectures sont conservés sur cet appareil.'),
      const SizedBox(height: 12),
      Text('Version mobile 1.1.0', style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12)),
    ]))),
  ]);
}
