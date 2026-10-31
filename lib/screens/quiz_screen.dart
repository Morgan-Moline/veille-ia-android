import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, List<dynamic>> _topics = {};
  String? _selectedTopic;
  List<Map<String, dynamic>> _session = [];
  int _index = 0;
  int _score = 0;
  int? _answer;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() { super.initState(); _loadBank(); }

  Future<void> _loadBank() async {
    try {
      final raw = await rootBundle.loadString('assets/data/question_bank.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final topics = (json['topics'] as Map<String, dynamic>).map((key, value) => MapEntry(key, List<dynamic>.from(value as List)));
      if (!mounted) return;
      setState(() { _topics = topics; _selectedTopic = topics.keys.first; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _start() {
    final pool = _topics[_selectedTopic] ?? _topics.values.expand((e) => e).toList();
    final questions = pool.map((q) => Map<String, dynamic>.from(q as Map)).toList()..shuffle(Random());
    setState(() { _session = questions.take(min(10, questions.length)).toList(); _index = 0; _score = 0; _answer = null; _finished = false; });
  }

  void _choose(int answer) {
    if (_answer != null) return;
    setState(() { _answer = answer; if (answer == _session[_index]['correctAnswer']) _score++; });
  }

  void _next() {
    if (_index == _session.length - 1) { setState(() => _finished = true); }
    else { setState(() { _index++; _answer = null; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_topics.isEmpty) return const Center(child: Text('La banque de questions est indisponible.'));
    if (_session.isEmpty) return _setup();
    if (_finished) return _result();
    final q = _session[_index];
    final answers = List<String>.from(q['answers'] as List);
    final correct = q['correctAnswer'] as int;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 28, 20, 28), children: [
      Row(children: [const Expanded(child: Text('RÉVISIONS BTS CG', style: TextStyle(fontSize: 11, letterSpacing: 1.3, fontWeight: FontWeight.w900, color: Color(0xFF64809B))), Text('${_index + 1} / ${_session.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF174A91)))]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (_index + 1) / _session.length, minHeight: 7, color: const Color(0xFF174A91), backgroundColor: const Color(0xFFDCE8F4))),
      const SizedBox(height: 24),
      Text(_selectedTopic ?? 'BTS CG', style: const TextStyle(color: Color(0xFF174A91), fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text((q['question'] ?? '').toString(), style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w900, color: Color(0xFF16324F))),
      const SizedBox(height: 22),
      ...List.generate(answers.length, (i) {
        final chosen = _answer == i;
        final isCorrect = i == correct;
        Color? bg;
        Color? border;
        if (_answer != null && isCorrect) { bg = const Color(0xFFE4F4EA); border = const Color(0xFF26834A); }
        else if (chosen && !isCorrect) { bg = const Color(0xFFFFE9E7); border = const Color(0xFFC43B32); }
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(
          onTap: () => _choose(i),
          borderRadius: BorderRadius.circular(16),
          child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bg ?? Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border ?? const Color(0xFFE6ECF2))),
            child: Row(children: [CircleAvatar(radius: 15, backgroundColor: const Color(0xFFEAF0F7), child: Text(String.fromCharCode(65 + i), style: const TextStyle(color: Color(0xFF174A91), fontWeight: FontWeight.w800))), const SizedBox(width: 12), Expanded(child: Text(answers[i], style: const TextStyle(fontWeight: FontWeight.w600))), if (_answer != null && isCorrect) const Icon(Icons.check_circle, color: Color(0xFF26834A))]),
          ),
        ));
      }),
      if (_answer != null) Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_answer == correct ? 'Bonne réponse !' : 'Pas tout à fait.', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16324F))),
        const SizedBox(height: 5),
        Text((q['explanation'] ?? '').toString(), style: const TextStyle(height: 1.4)),
      ])),
      const SizedBox(height: 18),
      FilledButton(onPressed: _answer == null ? null : _next, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF174A91), minimumSize: const Size.fromHeight(52)), child: Text(_index == _session.length - 1 ? 'Voir mon résultat' : 'Question suivante')),
    ]);
  }

  Widget _setup() => ListView(padding: const EdgeInsets.fromLTRB(20, 30, 20, 30), children: [
    Container(height: 150, decoration: BoxDecoration(color: const Color(0xFF174A91), borderRadius: BorderRadius.circular(22)), child: const Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [Icon(Icons.school, color: Colors.white, size: 30), SizedBox(height: 10), Text('Entraînement BTS CG', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), Text('500 questions • 10 thèmes', style: TextStyle(color: Colors.white70))]))),
    const SizedBox(height: 24),
    const Text('Choisis ton thème', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16324F))),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(value: _selectedTopic, decoration: const InputDecoration(labelText: 'Thème de révision'), items: _topics.keys.map((t) => DropdownMenuItem(value: t, child: Text('$t  •  ${_topics[t]!.length} questions'))).toList(), onChanged: (v) => setState(() => _selectedTopic = v)),
    const SizedBox(height: 18),
    FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('Démarrer une session de 10 questions'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF174A91), minimumSize: const Size.fromHeight(52))),
  ]);

  Widget _result() => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.emoji_events_outlined, size: 64, color: Color(0xFF174A91)),
    const SizedBox(height: 16),
    const Text('Session terminée !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF16324F))),
    const SizedBox(height: 8),
    Text('Tu as obtenu $_score / ${_session.length}', style: const TextStyle(fontSize: 18)),
    const SizedBox(height: 20),
    FilledButton(onPressed: _start, child: const Text('Recommencer')),
    TextButton(onPressed: () => setState(() { _session = []; _finished = false; }), child: const Text('Changer de thème')),
  ])));
}
