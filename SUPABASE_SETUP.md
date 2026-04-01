# Supabase configuration (OM project)

Ce document explique comment configurer Supabase pour l'application `OM` (CreditTrak).

## 1. Pré-requis

- Compte Supabase (https://app.supabase.com)
- Projet Supabase créé
- Accès aux valeurs suivante dans la section `Project > Settings > API` :
  - `URL` (exemple : `https://xxxxx.supabase.co`)
  - `anon public key`

## 2. Installer les dépendances

Dans le dossier du projet, exécuter :

```bash
flutter pub get
```

Le package `supabase_flutter` est déjà listé dans `pubspec.yaml`.

## 3. Initialiser Supabase dans `lib/main.dart`

Le code existant contient ces lignes :

```dart
await Supabase.initialize(
  url: 'https://VOTRE_PROJET.supabase.co',
  anonKey: 'VOTRE_ANON_KEY',
);
```

Remplacez `url` et `anonKey` par les valeurs de votre projet.

### Exemple :

```dart
await Supabase.initialize(
  url: 'https://abc123.supabase.co',
  anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (à remplacer)',
);
```

## 4. Protéger vos clés (optionnel mais recommandé)

Ne poussez pas vos clés dans git. Utilisez des variables d'environnement ou un fichier privé non versionné.

### Exemple avec `flutter_dotenv` :

1. Ajouter `flutter_dotenv` dans `pubspec.yaml`.
2. Créer un fichier `.env` :

```
SUPABASE_URL=https://abc123.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

3. Charger avec `dotenv` dans `main.dart` :

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
...
await dotenv.load(fileName: '.env');
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

4. Ajouter `.env` à `.gitignore`.

## 5. Vérifier la connexion

Démarrer l’application : `flutter run -d chrome` (ou target de votre choix) et valider que l’authentification et les requêtes fonctionnent.

## 6. Architecture du code dans le projet

- `lib/controllers/auth_controller.dart` : méthodes d’authentification (`signInWithPassword`, `signUp`, `signOut`).
- `lib/controllers/transaction_controller.dart` : gestion des flux `transactions` vers Supabase.
- `lib/models/transaction_model.dart` : conversion d/vers JSON.

---

### Commandes utiles

- Flutter doctor : `flutter doctor -v`
- Lister devices : `flutter devices`
- Lancer web : `flutter run -d chrome`

---

> Remplace toujours les valeurs de la clé anonyme avec celles de votre projet Supabase.
