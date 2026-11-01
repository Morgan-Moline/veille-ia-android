import 'package:flutter/material.dart';

class VeilleCategory {
  const VeilleCategory({required this.name, required this.shortName, required this.description, required this.color, required this.secondary, required this.icon, required this.imageKey, required this.eyebrow});
  final String name, shortName, description, imageKey, eyebrow;
  final Color color, secondary;
  final IconData icon;
}

const veilleCategories = <VeilleCategory>[
  VeilleCategory(name: 'Comptabilité & fiscalité', shortName: 'Comptabilité', description: 'TVA, fiscalité et actualités comptables', color: Color(0xFF438DBB), secondary: Color(0xFF79BDE5), icon: Icons.calculate_outlined, imageKey: 'comptabilite', eyebrow: 'COMPTABILITÉ • FISCALITÉ'),
  VeilleCategory(name: 'BTS Comptabilité-Gestion', shortName: 'Études', description: 'Cours, examens et ressources BTS CG', color: Color(0xFFD99A24), secondary: Color(0xFFF2C45B), icon: Icons.school_outlined, imageKey: 'etudes', eyebrow: 'CCI CAMPUS CENTRE'),
  VeilleCategory(name: 'Secteur professionnel', shortName: 'Secteur pro', description: 'Matériel agricole, location et concessionnaires', color: Color(0xFFC62828), secondary: Color(0xFFAEB8C3), icon: Icons.agriculture_outlined, imageKey: 'secteur_pro', eyebrow: 'CLOUÉ • CASE IH'),
];
