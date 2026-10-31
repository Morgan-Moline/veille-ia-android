# Migration et périmètre de Veille IA

## Dépôt cible
`Morgan-Moline/veille-ia-android` devient le dépôt de référence pour l'application mobile Flutter.

## Fonctionnalités reprises du site
| Fonction | Android |
|---|---|
| Trois catégories et codes couleur | Intégré |
| Visuels de catégories | Intégrés hors ligne |
| Chargement des articles depuis data.json | Intégré |
| Recherche | Intégré |
| Filtres Tous / Non lus / Favoris / Lus | Intégré |
| Tri chronologique | Intégré |
| Favoris | Intégré, stocké localement |
| Lu / non lu | Intégré, stocké localement |
| Résumés IA publiés avec les articles | Intégré dans les fiches |
| Ouverture de la source | Intégré |
| Banque de révision BTS CG | 500 questions / 10 thèmes intégrés |
| Choix de plusieurs thèmes de quiz | Intégré |
| Déclenchement d'une nouvelle veille | Intégré via le Worker existant |
| Suivi de génération sans bloquer l'interface | Intégré |
| Consultation des derniers articles sans réseau | Cache local intégré |

## Architecture cible
- Android Flutter : interface, navigation, préférences locales, cache et révisions.
- `veille-ia-data` : dépôt de données central. Il reste nécessaire au fonctionnement de l'application et du Worker tant que cette architecture est utilisée.
- Cloudflare Worker : déclenchement de la génération. Le traitement continue côté serveur, même si l'application est fermée.
- Site web : interface séparée et temporaire pendant la validation de l'application Android.

## Dépôts historiques
- `veille-ia-app` : source de migration. Les 500 questions, visuels de catégories et identifiant Shorebird ont été repris dans le dépôt Android cible.
- `veille-ia-web` : source de parité fonctionnelle et visuelle. L'application Android ne référence plus ce dépôt.
- `veille-ia-data` : ne pas supprimer à ce stade. C'est la source de données en production.

## Critères avant archivage/suppression des anciens dépôts
1. Le workflow Android CI doit terminer au vert.
2. L'APK doit être installé et testé sur le téléphone Android réel.
3. Les articles, filtres, favoris, lus/non lus, résumés, quiz et déclenchement Cloudflare doivent être vérifiés.
4. Vérifier la mise à jour Shorebird avec l'identifiant d'application conservé.
5. Confirmer que l'application n'utilise plus aucun fichier hébergé dans `veille-ia-app` ou `veille-ia-web`.
6. Seulement après ces contrôles, archiver puis supprimer les dépôts historiques concernés. Le dépôt `veille-ia-data` reste en service.

Aucune suppression de dépôt n'est effectuée par cette migration.
