import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryArtwork extends StatelessWidget {
  const CategoryArtwork({super.key, required this.imageKey, this.fit = BoxFit.cover});
  final String imageKey;
  final BoxFit fit;

  static final Map<String, Future<Uint8List>> _cache = {};

  static Future<Uint8List> _loadImage(String key) async {
    final raw = await rootBundle.loadString('assets/data/category_$key.txt');
    return base64Decode(raw);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _cache.putIfAbsent(imageKey, () => _loadImage(imageKey)),
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null) return const ColoredBox(color: Color(0xFFE8EEF4));
      return Image.memory(bytes, fit: fit, gaplessPlayback: true);
    },
  );
}
