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
| 3 | Écran principal | Fait |
| 4 | Ajouter et corriger un enchaînement | Fait |
| 5 | Séance de révision vocale | Fait |
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

## La voix

La voix n'est pas la synthèse vocale du téléphone : chaque annonce a été
enregistrée une fois, d'un trait, avec la synthèse vocale de Gemini, dans
`assets/voice/`. Comme un entraîneur, elle en dit moins quand ça
s'accélère : « Crochet arrière au corps » en lent, « Crochet corps » en
moyen, « Crochet » en rapide (89 annonces longues, 51 courtes). La cible est
toujours annoncée et affichée quand elle a été choisie (« Crochet avant à la
tête »). La voix est
la même sur tous les téléphones et fonctionne hors ligne. Un test vérifie
que chaque annonce, à chaque palier, a son enregistrement. Elle est jouée avec `just_audio`, derrière le contrat
`Speaker` (`lib/platform/clip_speaker.dart`).

## Dépendances

| Paquet | Pourquoi |
|---|---|
| `freezed`, `freezed_annotation`, `build_runner` | Les objets du modèle sont immuables. `freezed` écrit pour eux `==`, `hashCode`, `copyWith` et `toString` : sans lui, chaque ajout de champ obligerait à modifier ces quatre méthodes à la main, avec le risque d'en oublier une. Le mode « classe classique » est utilisé : la classe reste une classe Dart ordinaire. |
| `drift`, `drift_flutter`, `drift_dev` | ORM sur SQLite. Les tables sont décrites en Dart, drift écrit le SQL. Choisi pour les migrations versionnées (l'application va évoluer) et pour les requêtes vérifiées à la compilation. drift n'est utilisé que dans `lib/data/drift/`. |
| `provider` | Rend les services (repositories, horloge) accessibles à tous les écrans, comme le conteneur de services de Symfony : un écran demande ce qu'il utilise, sans qu'on le lui transmette d'écran en écran. Choisi en vue de la V2 (profil et statistiques partagés entre écrans). |
| `intl` | Les dates en français sur la fiche d'un enchaînement (« 24 novembre 2026 »). Déjà présent par `flutter_localizations`. |
| `just_audio` | Joue les annonces enregistrées de la voix, et les accélère un peu sans changer la hauteur de la voix (paliers). Utilisé seulement dans `lib/platform/`, derrière le contrat `Speaker` : les tests utilisent un faux. |
| `wakelock_plus` | Garde l'écran allumé pendant la séance, quand le téléphone est posé. Derrière le contrat `ScreenAwake`, pour la même raison. |
| `flutter_localizations` (SDK) | Les textes de Material en français (infobulles, boutons système). |

Chaque paquet est ajouté à l'étape qui s'en sert.

Illustrations : le personnage, ses poses et le logo sont générés par IA
(Gemini), à partir d'une fiche personnage commune ; les prompts sont gardés
pour que la série reste homogène.

Polices : [Barlow et Barlow Condensed](https://github.com/jpt/barlow), de
Jeremy Tribby, sous licence SIL Open Font License 1.1
(`assets/fonts/OFL.txt`). Elles sont embarquées dans l'application, qui
fonctionne hors ligne.

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

Pour essayer l'application avec dix enchaînements de démonstration
(échéances variées), sur une installation neuve :

```bash
flutter run --dart-define=CADENCE_DEMO=true
```

Sans cette option, l'application démarre vide, comme chez un nouvel
utilisateur.

## Architecture

```
lib/
  models/   objets et règles métier, purs (aucun Flutter, aucune base)
  data/     contrats des repositories ; drift/ : leur implémentation SQLite
  state/    un contrôleur par écran (ChangeNotifier), les quatre états,
            les contrats de la voix et de l'écran allumé
  platform/ leur implémentation Android (just_audio, wakelock_plus)
  ui/       écrans et composants ; theme/ : toutes les couleurs
```

Un écran ne parle qu'à son contrôleur, qui ne connaît que les contrats de
`data/`. Les services sont créés une fois dans `main.dart`.

## Vérifier la qualité

```bash
dart run build_runner build
flutter analyze
flutter test
```

Ces commandes sont lancées automatiquement à chaque `push` par GitHub
Actions (`.github/workflows/ci.yml`).
