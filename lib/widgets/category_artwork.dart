import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryArtwork extends StatelessWidget {
  const CategoryArtwork({super.key, required this.imageKey, this.fit = BoxFit.cover});
  final String imageKey;
  final BoxFit fit;

  static final Future<Map<String, Uint8List>> _images = _loadImages();

  static Future<Map<String, Uint8List>> _loadImages() async {
    final raw = await rootBundle.loadString('assets/data/category_images.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, base64Decode(value as String)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, Uint8List>>(
    future: _images,
    builder: (context, snapshot) {
      final bytes = snapshot.data?[imageKey];
      if (bytes == null) return const ColoredBox(color: Color(0xFFE8EEF4));
      return Image.memory(bytes, fit: fit, gaplessPlayback: true);
    },
  );
}
