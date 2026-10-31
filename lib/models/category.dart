import 'package:flutter/material.dart';

class VeilleCategory {
  const VeilleCategory({required this.name, required this.shortName, required this.description, required this.color, required this.secondary, required this.icon, required this.imageKey, required this.eyebrow});
  final String name, shortName, description, imageKey, eyebrow;
  final Color color, secondary;
  final IconData icon;
}

const veilleCategories = <VeilleCategory>[
  VeilleCategory(name: 'Comptabilité & fiscalité', shortName: 'Comptabilité', description: 'TVA, fiscalité et actualités comptables', color: Color(0xFF2468B4), secondary: Color(0xFFF28C28), icon: Icons.calculate_outlined, imageKey: 'comptabilite', eyebrow: 'COMPTABILITÉ • FISCALITÉ'),
  VeilleCategory(name: 'BTS Comptabilité-Gestion', shortName: 'Études', description: 'Cours, examens et ressources BTS CG', color: Color(0xFF174A91), secondary: Color(0xFF55A6E8), icon: Icons.school_outlined, imageKey: 'etudes', eyebrow: 'CCI CAMPUS CENTRE'),
  VeilleCategory(name: 'Secteur professionnel', shortName: 'Secteur pro', description: 'Matériel agricole, location et concessionnaires', color: Color(0xFFC62828), secondary: Color(0xFFEF5350), icon: Icons.agriculture_outlined, imageKey: 'secteur_pro', eyebrow: 'CLOUÉ • CASE IH'),
];
