# Cadence

[![CI](https://github.com/Antony35/Cadence/actions/workflows/ci.yml/badge.svg)](https://github.com/Antony35/Cadence/actions/workflows/ci.yml)

Carnet d'enchaînements de sports de combat, sur Android et **hors ligne**.

Après un cours, on note les enchaînements vus en touchant leurs techniques une
à une. Chaque jour, l'application propose ceux qu'il est temps de réviser et
les dicte à voix haute, de plus en plus vite.

> Projet en cours de développement. Ce README est complété à chaque étape.

## À qui s'adresse l'application

À un pratiquant de sport de combat qui suit des cours en club et oublie, d'une
semaine à l'autre, les enchaînements montrés par son professeur.

## Avancement

| Étape | Contenu | État |
|---|---|---|
| 0 | Projet, thème, intégration continue | Fait |
| 1 | Modèles et règles métier | Fait |
| 2 | Base de données SQLite | Fait |
| 3 | Écran principal | À venir |
| 4 | Ajouter et corriger un enchaînement | À venir |
| 5 | Séance de révision vocale | À venir |
| 6 | Réglages et finitions | À venir |
| 7 | Livraison | À venir |

## Le catalogue des techniques

L'application contient 41 techniques (poings, coudes, pieds, genoux, défenses,
déplacements), nommées selon le glossaire technique de la FFKMDA et l'usage
des clubs français. C'est un **référentiel**, pas une donnée de
démonstration : il est inséré dans la base au premier lancement et ne peut
pas être modifié par l'utilisateur.

## Les données

Une base SQLite locale, six tables : techniques (et leurs côtés et cibles
acceptés), enchaînements, étapes, révisions. La base garantit elle-même son
intégrité : valeurs autorisées (`CHECK`), aucun doublon d'enchaînement
(`UNIQUE`), étapes et révisions supprimées avec leur enchaînement (clés
étrangères en cascade). L'application n'accède à la base que par trois
contrats (`lib/data/repositories.dart`).

Le dossier `drift_schemas/` garde une photo du schéma de chaque version : la
base d'un téléphone pourra être migrée vers la version suivante sans perdre de
données.

## Dépendances

| Paquet | Pourquoi |
|---|---|
| `freezed`, `freezed_annotation`, `build_runner` | Les objets du modèle sont immuables. `freezed` écrit pour eux `==`, `hashCode`, `copyWith` et `toString` : sans lui, chaque ajout de champ obligerait à modifier ces quatre méthodes à la main, avec le risque d'en oublier une. Le mode « classe classique » est utilisé : la classe reste une classe Dart ordinaire. |
| `drift`, `drift_flutter`, `drift_dev` | ORM sur SQLite. Les tables sont décrites en Dart, drift écrit le SQL. Choisi pour les migrations versionnées (l'application va évoluer) et pour les requêtes vérifiées à la compilation. drift n'est utilisé que dans `lib/data/drift/`. |

Chaque paquet est ajouté à l'étape qui s'en sert.

## Lancer le projet

Prérequis : Flutter 3.47.9 (canal stable) et un téléphone ou un émulateur
Android.

```bash
flutter pub get
dart run build_runner build
flutter run
```

La deuxième commande génère les fichiers `*.freezed.dart` et `*.g.dart`
(voir « Dépendances »). Ils ne sont pas versionnés : on la relance après
chaque modification d'un modèle ou d'une table.

## Vérifier la qualité

```bash
dart run build_runner build
flutter analyze
flutter test
```

Ces commandes sont lancées automatiquement à chaque `push` par GitHub
Actions (`.github/workflows/ci.yml`).
