# Veille IA — Android

Application Flutter mobile officielle de Veille IA. Elle reprend les fonctionnalités du site dans une interface simplifiée et adaptée au téléphone.

## Fonctionnalités intégrées
- Flux d'actualités partagé depuis `veille-ia-data/data.json`
- Trois univers : Comptabilité & fiscalité, BTS Comptabilité-Gestion, Secteur professionnel
- Identité visuelle du site conservée : couleurs, visuels et accents de catégorie
- Recherche dans les titres, descriptions, résumés, sources et catégories
- Filtres Tous / Non lus / Favoris / Lus, tri chronologique
- Favoris et lectures persistés localement avec SharedPreferences
- Fiche article avec résumé IA, description, source et ouverture de l'article
- Déclenchement sécurisé d'une nouvelle veille via le Worker Cloudflare existant
- Suivi asynchrone non bloquant : la génération se poursuit côté serveur
- Banque intégrée de 500 questions BTS CG réparties sur 10 thèmes

## Services communs
- Données : https://raw.githubusercontent.com/Morgan-Moline/veille-ia-data/main/data.json
- Déclencheur : https://veille-ia-trigger.themomo450.workers.dev/

Les trois images de catégories et la banque de questions sont embarquées dans ce dépôt : l'application ne dépend pas des dépôts historiques pour ces ressources. Le secret Cloudflare est saisi par l'utilisateur et n'est pas stocké dans le code.

## Environnement
- Flutter stable / Dart 3
- Android applicationId conservé : `com.example.veille_ia`
- Identifiant Shorebird historique conservé pour préparer la continuité des mises à jour

## Première préparation locale
Après clonage du dépôt, si le dossier Android natif doit être régénéré :
```bash
flutter create --platforms=android --org com.example --project-name veille_ia --no-pub .
flutter pub get
flutter run
```

## CI
GitHub Actions régénère la plateforme Android, analyse le code, exécute les tests et construit un APK release à chaque push sur `main`. L'APK est publié comme artefact du workflow.
