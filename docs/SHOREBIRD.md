# Publication Android avec Shorebird

Le dépôt utilise Shorebird pour publier des correctifs Dart à distance.

## Secrets GitHub requis

Dans Settings > Secrets and variables > Actions, créer les secrets suivants :

- SHOREBIRD_TOKEN : clé API créée dans Shorebird Console > Account > API Keys.
- ANDROID_KEYSTORE_BASE64 : contenu Base64 du fichier JKS de signature.
- ANDROID_KEYSTORE_PASSWORD : mot de passe du keystore.
- ANDROID_KEY_PASSWORD : mot de passe de la clé.
- ANDROID_KEY_ALIAS : alias de la clé (veilleia).

Ne jamais committer le keystore, key.properties, ni les valeurs des secrets.

## Workflows

- Android CI : analyse, tests et APK de contrôle.
- Shorebird Release Android : publication manuelle d'une nouvelle version native (workflow_dispatch).
- Shorebird Patch Android : publication manuelle d'un correctif Dart OTA (workflow_dispatch).

Une release Shorebird doit être installée sur le téléphone avant de pouvoir recevoir ses patches. Les modifications natives (plugins, manifeste, Gradle, moteur Flutter) nécessitent une nouvelle release et une installation classique ; les changements Dart compatibles peuvent être livrés par patch.
