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
| 1 | Modèles et règles métier | À venir |
| 2 | Base de données SQLite | À venir |
| 3 | Écran principal | À venir |
| 4 | Ajouter et corriger un enchaînement | À venir |
| 5 | Séance de révision vocale | À venir |
| 6 | Réglages et finitions | À venir |
| 7 | Livraison | À venir |

## Lancer le projet

Prérequis : Flutter 3.47.9 (canal stable) et un téléphone ou un émulateur
Android.

```bash
flutter pub get
flutter run
```

## Vérifier la qualité

```bash
flutter analyze
flutter test
```

Ces deux commandes sont lancées automatiquement à chaque `push` par GitHub
Actions (`.github/workflows/ci.yml`).
