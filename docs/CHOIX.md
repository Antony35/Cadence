# CHOIX — Cadence

Décisions du projet, expliquées, avec les questions qu'un jury peut poser.
Fichier de travail qui a servi à préparer le README et l'oral, tenu étape par
étape pendant le développement et versionné avec la V1.

Les codes entre parenthèses (F12, D3, S4, T7…) renvoient aux exigences et aux
tests de la spécification, restée hors du dépôt : F pour les fonctions, D
pour les règles métier, N pour la navigation, C pour les composants
réutilisés, S pour les situations d'échec, V pour l'identité visuelle, R
pour les règles techniques, T pour les tests automatiques.

## Avant le code — les choix de conception

### Pourquoi SQLite

Cadence doit marcher sans réseau ni serveur. PostgreSQL et MariaDB sont des
bases **serveur** : un programme tourne sur une machine et l'application lui
parle par le réseau. SQLite est une base **embarquée** : une bibliothèque dans
l'application, et la base est un fichier sur le téléphone.

Parmi les solutions locales, les données de Cadence sont **liées entre
elles** : un enchaînement a des étapes, chaque étape pointe vers une
technique. « Les enchaînements qui contiennent un Low kick » est une jointure,
exactement ce que SQL sait faire. `shared_preferences` ne sait pas chercher,
un fichier JSON se réécrit en entier à chaque modification.

### Le modèle de données

Six tables (`docs/mcd.mmd`). Quatre principes :

1. **Une case, une valeur.** Les côtés et cibles acceptés par une technique
   sont dans des tables de liaison (`technique_sides`, `technique_targets`),
   pas dans un texte « lead,rear ».
2. **La base refuse les valeurs inconnues.** Chaque colonne à valeurs fixes a
   une contrainte `CHECK`. On n'a pas créé de tables `sides` ou `grades` :
   elles se justifient quand la liste change sans toucher au code, et ici
   chaque valeur déclenche du code.
3. **Zéro doublon garanti par la base.** `combos.signature` est une empreinte
   de la séquence, marquée unique.
4. **Identifiants entiers.** Tout est local : rien à protéger, et l'entier est
   la clé de rangement de SQLite, donc l'accès le plus rapide. Un UID
   deviendrait utile si deux appareils synchronisaient leurs données.

`position` n'est pas redondante avec l'identifiant : l'identifiant dit **qui**
est la ligne, la position dit **où** elle se range.

### La boîte de Leitner

Six boîtes, d'intervalles 1, 3, 7, 14, 30 et 60 jours. Difficile → boîte 1 ;
Correct → boîte suivante ; Facile → deux boîtes plus loin. `box` et `due_on`
sont stockés dans `combos` alors qu'on pourrait les recalculer depuis
`reviews` : « quoi réviser aujourd'hui » devient une requête simple et rapide.

### Un seul écran principal

Les règles Android réservent la barre du bas à 3 à 5 destinations d'importance
égale. Cadence a deux actions principales, réviser et ajouter : une carte avec
« Commencer » et un bouton flottant « + », comme Anki ou Google Keep. Le
catalogue, rarement ouvert, va dans le menu latéral.

### Le vocabulaire

Les noms suivent le glossaire technique de la FFKMDA et l'usage des clubs :
poings, coudes et genoux en français, coups de pied en anglais (Low kick,
Middle kick, High kick). Le Front kick (percuté) et le Teep (poussé) sont deux
techniques.

## Étape 0 — Cadrage

### Ce qui a été fait

Projet Flutter Android, dépôt Git relié à GitHub, thème clair et sombre, écran
provisoire, tests de contraste, intégration continue, README initial.

### Les choix

**Android seulement** (`--platforms android`). Le cours demande un APK ;
générer iOS, web et bureau ajouterait des dossiers jamais utilisés.

**Identifiant `io.github.antony35.cadence`.** Un identifiant d'application est
un nom de domaine à l'envers. Sans domaine personnel, celui de la page GitHub
est la convention.

**Aucune dépendance ajoutée pour l'instant.** Chaque paquet arrive à l'étape
qui s'en sert, avec sa justification. `cupertino_icons` (icônes iOS), ajouté
par défaut, est retiré.

**Des règles d'analyse plus strictes** (`analysis_options.yaml`) :
- `strict-casts`, `strict-inference`, `strict-raw-types` : Dart ne devine plus
  un type à ma place, il faut l'écrire. Les erreurs apparaissent à l'écriture
  plutôt qu'à l'exécution.
- `always_use_package_imports`, `directives_ordering` : tous les imports ont
  la même forme et le même ordre.
- `unawaited_futures` : signale un `Future` qu'on a oublié d'attendre, une
  source classique de bugs.

**Les couleurs dans un seul fichier** (`lib/ui/theme/app_theme.dart`). Les
écrans lisent `Theme.of(context).colorScheme` : changer de thème ou de couleur
ne touche aucun écran.

**L'or foncé pour le texte, l'or clair pour les aplats.** L'or `#C9971F` sur
fond ivoire a un contraste de 2,5:1 : illisible en petit texte. `primary` est
donc un or foncé `#7A5A0E` (5,9:1), et un or pâle `#F3DFA2` remplit
`primaryContainer`, où le texte est presque noir (12:1).

**Des tests de contraste** (`test/theme_contrast_test.dart`). Ils calculent
le rapport WCAG de chaque paire texte/fond autorisée et exigent 4,5:1, dans
les deux thèmes. Si quelqu'un change une couleur, le test le dit avant
l'utilisateur.

**La CI** (`.github/workflows/ci.yml`). À chaque push, une machine de GitHub
installe la même version de Flutter que la mienne, puis vérifie le formatage,
lance `flutter analyze` et les tests. Le badge du README affiche le résultat.

**Fichiers cachés de Git** par `.git/info/exclude` : `docs/`, `CLAUDE.md`,
`.idea/`. Contrairement à `.gitignore`, ce fichier n'est pas dans le dépôt :
même les noms restent invisibles sur GitHub.
À la livraison, `docs/` devient `docs/*` suivi de `!docs/CHOIX.md` : seul
ce fichier sort de l'exclusion (étape 7).

### Un piège rencontré

Le test « l'application suit le réglage clair ou sombre » échouait après le
changement de thème : `MaterialApp` **anime** le passage d'un thème à l'autre
(200 ms). Un seul `pump()` regardait l'écran au milieu de l'animation.
`pumpAndSettle()` attend la fin. Il est sûr ici parce qu'aucune animation
infinie (roue de chargement) ne tourne.

### Questions du jury

**Pourquoi une CI pour un projet seul ?**
Elle prouve que le projet se construit et passe ses tests sur une machine
neuve, pas seulement sur la mienne. Elle bloque aussi l'oubli le plus
courant : pousser sans avoir lancé les tests.

**Pourquoi fixer la version de Flutter dans la CI ?**
Pour que la CI et mon poste ne puissent pas être en désaccord. Avec « la
dernière version », une mise à jour de Flutter pourrait faire échouer la CI
sans que j'aie rien changé.

**Pourquoi tester des couleurs ?**
Le contraste est une règle chiffrée (4,5:1 pour du texte), donc vérifiable
automatiquement. Un test coûte dix lignes et protège les deux thèmes.

**Que contient `pubspec.yaml` ?**
Le nom, la version (`1.0.0` pour l'utilisateur, `+1` pour Android, qui doit
augmenter à chaque APK publié), la version de Dart exigée et les dépendances.

**Pourquoi `abstract final class AppTheme` ?**
La classe ne sert qu'à regrouper des constantes : `abstract` interdit d'en
créer une instance, `final` interdit d'en hériter.

## Étape 1 — Modèles et règles

### Ce qui a été fait

Les quatre objets (`Technique`, `Combo`, `ComboStep`, `Review`), le catalogue
des 41 techniques, et les règles métier en classes pures : libellés (D3, D4),
validation (F11), signature (D8), Leitner (D5 à D7), recherche et filtre (C1).
Tests T1 à T6 et T8. Aucun écran, aucune base : `lib/models/` ne dépend pas de
Flutter.

| Fichier | Contenu |
|---|---|
| `lib/models/technique.dart` | `Technique` et les énumérations `Family`, `Side`, `Target` |
| `lib/models/catalog.dart` | Les 41 techniques, dans l'ordre d'insertion |
| `lib/models/combo.dart` | `ComboStep`, `Combo`, `ComboRules` (libellés, signature, validation) |
| `lib/models/review.dart` | `Review` et l'énumération `Grade` |
| `lib/models/leitner.dart` | Boîtes, échéances, « à réviser », « en retard », ordre |
| `lib/models/dates.dart` | `dateOnly` et `addDays` |
| `lib/models/search.dart` | `SearchFilter` et `normalize` |
| `test/models/` | Un fichier de tests par règle, et `fixtures.dart` (aides communes) |

### Les notions

**Classe immuable.** Tous les champs sont `final` : une fois créé, l'objet ne
change plus. Pour « modifier », on crée une copie avec `copyWith`, comme
`DateTimeImmutable::modify()` en PHP. Avantage : un objet partagé entre deux
écrans ne peut pas être changé dans le dos de l'un d'eux.

**Égalité.** En Dart, `a == b` compare par défaut l'**identité** (comme `===`
en PHP) : deux étapes « Crochet avant » créées séparément seraient
différentes. `freezed` génère un `==` qui compare les valeurs.

**Énumération.** Une liste fermée de valeurs (`Family.punch`…). Chaque valeur
porte son libellé français. En base, on écrit `.name` (`punch`), le nom de la
valeur, qui est exactement le code du MCD : rien à recopier deux fois.

**Null safety.** `Side?` peut valoir `null`, `Side` jamais : le compilateur
refuse de lire `side.label` tant qu'on n'a pas vérifié que `side` n'est pas
`null`. Le code ne contient aucun `!` (« je promets que ce n'est pas null »).

**Test unitaire.** Une fonction appelée avec des valeurs choisies, et
`expect(résultat, attendu)`. Attention : l'ordre est l'inverse de PHPUnit
(`assertSame($attendu, $résultat)`).

### Les choix

**`freezed`, en mode « classe classique ».** On écrit une classe Dart normale
(constructeur, champs `final`, méthodes) ; `freezed` ajoute `==`, `hashCode`,
`copyWith` et `toString` dans un fichier `*.freezed.dart`. Écrites à la main,
ces quatre méthodes énumèrent chaque champ : le jour où l'on ajoute un champ,
on oublie de l'y ajouter. L'autre écriture de `freezed` (un `factory` qui
génère aussi les champs) aurait été plus courte mais moins lisible.

**Les fichiers générés ne sont pas versionnés.** Comme `vendor/` en PHP, ils
se reconstruisent (`dart run build_runner build`) ; la CI les génère avant
`flutter analyze`. Le formatage est vérifié **avant** la génération : on ne
juge que le code écrit à la main.

**Une technique est identifiée par son `slug`.** Le catalogue est écrit dans
le code et inséré dans la base au premier lancement, sur chaque téléphone :
il n'existe pas encore d'`id` quand on l'écrit. L'`id` et la `position`
restent dans la couche `data/`.

**Position dans tout le catalogue (1 à 41), unique.** L'ordre de
`catalog.dart` donne la position : poings, coudes, pieds, genoux, défenses,
déplacements. Un seul `ORDER BY position` range le catalogue par famille. Avec
un rang par famille, `ORDER BY family` trierait les familles par ordre
alphabétique de leur code (`defense`, `elbow`…), pas dans l'ordre voulu.

**Un `Combo` existe toujours en base.** Le formulaire ne manipule qu'un nom et
une liste d'étapes ; s'il est quitté, rien n'est enregistré (avec la question
« Quitter sans enregistrer ? », F15). Ainsi `Combo.id` n'est jamais `null`.

**La validation renvoie une erreur, elle ne plante pas.**
`ComboRules.validate` renvoie `ComboError.tooFewSteps`… ou `null` : pendant la
saisie, un enchaînement incomplet est normal. Le message français sera choisi
par l'écran (étape 4). En revanche, `ComboStep` lève une `ArgumentError` pour
un côté ou une cible que la technique refuse : l'écran ne le propose jamais,
c'est donc un bug.

**Une signature lisible** : `jab:lead:head|low_kick:rear:-`. Au plus 12
étapes, donc un texte court ; lisible quand on cherche un bug ; aucun paquet
de hachage ; stable, puisque le `slug` ne change jamais.

**Les dates sans bibliothèque.** Un jour est un `DateTime` local à minuit.
`addDays` reconstruit la date (`DateTime(a, m, j + n)`) au lieu d'ajouter
`n × 24 h` : le jour du passage à l'heure d'hiver dure 25 h. Aucune fonction
de `models/` ne lit l'horloge : le jour est passé en paramètre, les tests ne
dépendent pas de la date réelle. Règle commune avec `freezed` : un paquet
quand il remplace beaucoup de code répétitif ou risqué, du code maison quand
c'est dix lignes. `intl` viendra pour **afficher** les dates en français.

**Recherche sans accents par une petite table** (é→e, ç→c, œ→oe) : une
quinzaine de lettres, pas besoin d'un paquet.

**Les noms prononcés** (`spokenName`) : « Djab », « Oveur-hande »,
« Superman peunche ». Retirés à l'étape 5 avec la voix enregistrée, qui
prononce bien les vrais noms.

### Questions du jury

**Pourquoi `freezed` plutôt que d'écrire `==` à la main ?**
Pour ne pas oublier un champ dans `==` ou `copyWith` le jour où l'on en ajoute
un. Le code généré est vérifié par `flutter analyze` et les tests.

**Pourquoi pas de `DateTime.now()` dans les modèles ?**
Une fonction qui lit l'horloge donne un résultat différent chaque jour : son
test deviendrait faux demain. On lui passe « aujourd'hui ».

**Pourquoi `addDays` plutôt que `add(Duration(days: 1))` ?**
`Duration(days: 1)` vaut 24 h. Le 25 octobre 2026 dure 25 h en France :
minuit + 24 h donne 23 h le même jour. Le test `addDays stays at midnight`
le vérifie.

**Pourquoi la signature ne contient-elle pas le nom ?**
Deux enchaînements identiques avec deux noms différents restent un doublon :
c'est la séquence de coups qu'on révise, pas son nom.

**Où sont les messages d'erreur en français ?**
Dans les écrans (étape 4). Les modèles renvoient une valeur (`ComboError`),
l'écran choisit le texte : la règle est testable sans interface.

## Étape 2 — Base de données

### Ce qui a été fait

Les six tables du MCD avec drift, le catalogue inséré à la création, trois
contrats de repository et leur implémentation, les transactions. Tests T9 à
T11 sur une vraie base SQLite en mémoire. Aucun écran : l'application
n'ouvre pas encore la base (étape 3).

| Fichier | Contenu |
|---|---|
| `lib/data/repositories.dart` | **À lire en premier.** Les trois contrats : ce que l'application peut demander à la base |
| `lib/data/exceptions.dart` | `DuplicateComboException`, `NotFoundException` |
| `lib/data/drift/tables.dart` | Les six tables, leurs `CHECK`, clés étrangères et index |
| `lib/data/drift/database.dart` | `AppDatabase` : ouverture, version, création, catalogue, `PRAGMA foreign_keys` |
| `lib/data/drift/converters.dart` | Comment une date part en base et en revient (D9) |
| `lib/data/drift/drift_technique_repository.dart` | Le catalogue lu depuis la base |
| `lib/data/drift/drift_combo_repository.dart` | Créer, lire, modifier, supprimer un enchaînement |
| `lib/data/drift/drift_review_repository.dart` | Enregistrer une note et déplacer l'enchaînement de boîte |
| `drift_schemas/drift_schema_v1.json` | Photo du schéma de la version 1, pour les migrations |
| `test/data/` | Contraintes de la base, dates, repositories (T9 à T11) |

`lib/data/drift/` est le seul dossier qui connaît drift. Changer de technique
de stockage ne toucherait que lui.

### Les notions

**`Future`, `async`, `await`.** Lire le disque prend du temps : une méthode
de repository renvoie un `Future<Combo>`, la **promesse** d'un `Combo`.
`await` attend le résultat sans bloquer l'écran, qui continue à se dessiner.
Une fonction qui contient `await` est marquée `async` et renvoie elle-même un
`Future`. PHP n'a pas d'équivalent courant : Doctrine bloque jusqu'à la
réponse.

**ORM.** drift fait le lien entre des classes Dart et des tables, comme
Doctrine. On décrit une table en Dart (`tables.dart`), drift écrit le
`CREATE TABLE` et une classe par ligne (`ComboRow`…), dans
`database.g.dart`. Les requêtes s'écrivent en Dart
(`select(combos)..where(...)`, l'équivalent du QueryBuilder) ou en SQL brut
(`customSelect`, l'équivalent d'une requête native).

**Transaction.** Plusieurs écritures qui réussissent toutes ou n'ont aucun
effet. Dans `db.transaction(() async { ... })`, toute requête fait partie de
la transaction ; une exception annule tout (*rollback*). Comme
`beginTransaction()` / `commit()` / `rollBack()` de Doctrine, sans les écrire.

**Jointure.** `INNER JOIN` relie deux tables par une colonne commune. Ici, les
étapes sont jointes à leur enchaînement pour appliquer le même filtre (par
exemple « seulement ceux à réviser »).

**Contrainte.** Une règle que la base vérifie elle-même à chaque écriture :
`UNIQUE`, `CHECK`, clé étrangère. Même un bug dans le code Dart ne peut pas
enregistrer une boîte 7.

**Contrat (`abstract interface class`).** L'équivalent d'une `interface` PHP.
L'écran ne connaîtra que `ComboRepository` ; aujourd'hui l'implémentation est
`DriftComboRepository`, dans les tests d'écran ce sera un faux en mémoire.

### Les choix

**drift plutôt que `sqflite` (SQL écrit à la main).** `sqflite` suffisait
pour six tables. drift a été choisi parce que l'application va évoluer
(statistiques, profil) : les migrations deviennent versionnées et vérifiables
(`drift_schemas/` garde une photo de chaque version), une faute de nom de
colonne est vue à la compilation, et le SQL reste visible quand on le
souhaite. Coût : un second générateur de code et un temps d'apprentissage.
Les classes générées s'appellent `*Row` et restent dans `data/` : les modèles
de l'étape 1 n'ont pas changé.

**Les `CHECK` sont construits depuis les énumérations.**
`isOneOf(family, Family.values)` donne
`CHECK("family" IN ('punch', 'elbow', …))`. Ajouter une valeur à l'énumération
met la base à jour : la liste n'est écrite qu'une fois.

**Trois repositories.** `TechniqueRepository` (catalogue),
`ComboRepository` (enchaînements), `ReviewRepository` (notes, et plus tard
les statistiques). Une note modifie aussi l'enchaînement (boîte, échéance) :
`ReviewRepository.record` le fait dans sa propre transaction, ce que drift
rend simple.

**Le catalogue est lu depuis la base**, sa seule source pendant que
l'application tourne ; `catalog.dart` ne sert qu'à la remplir à la création.
Il est lu une fois puis gardé en mémoire : il ne change jamais.

**Deux requêtes pour relire les enchaînements, pas N+1.** Une pour les
enchaînements, une pour toutes leurs étapes (triées par enchaînement puis
position), rangées ensuite sous leur enchaînement en Dart. Deux requêtes,
qu'il y ait 3 enchaînements ou 300. Une seule jointure aurait répété chaque
enchaînement jusqu'à 12 fois.

**Une requête optimisée quand c'est utile.** `findDue(today)` ne lit que les
enchaînements à réviser (`WHERE due_on <= ?`) grâce à l'index sur `due_on`.
Un test vérifie avec `EXPLAIN QUERY PLAN` que SQLite utilise bien cet index.
L'écran principal, lui, affiche tout : il charge tout une fois et compte en
Dart.

**L'ordre D7 en SQL.** `ORDER BY due_on, box, created_at, id`, le même ordre
que `Leitner.compare` ; un test compare les deux.

**Modifier = effacer les étapes puis les réécrire**, dans la transaction.
Comparer l'ancienne et la nouvelle liste serait fragile : déplacer une étape
décale toutes les positions, et `(combo_id, position)` est la clé primaire.
L'`id`, la date de création, la boîte, l'échéance et les révisions sont
conservés (F14).

**Le doublon est vérifié dans la transaction, avant d'écrire.**
`DuplicateComboException` porte l'`id` de l'enchaînement existant, pour
« Ouvrir l'existant » (F12). La contrainte `UNIQUE` reste en place comme filet
de sécurité, mais on ne lit pas son message : dans l'application, drift
travaille dans un fil d'exécution séparé (*isolate*) et emballe l'erreur
SQLite autrement que dans les tests. Ce changement par rapport à l'idée de
départ (« attraper l'erreur UNIQUE ») rend le code identique partout.

**Une écriture qui ne touche aucune ligne lève `NotFoundException` (R5)** :
modifier ou supprimer un enchaînement qui n'existe plus ne passe pas en
silence.

**Les instants en UTC, les jours en local (D9).** `created_at`,
`updated_at`, `reviewed_at` : `2026-11-24T20:47:12.345678Z`, relus en heure
locale. UTC n'est jamais ambigu, même la nuit où 2 h 30 existe deux fois.
`due_on` : `2026-11-27`, car un jour n'existe qu'en heure locale. Les instants
ont toujours 6 décimales : sinon `12.000Z` se rangerait après `12.000500Z`
dans un tri de texte. Un instant relu est identique à l'original, microsecondes
comprises.

**Une note ne change pas `updated_at`.** Il dit quand l'enchaînement a été
**modifié** (F16) ; la date des révisions est dans `reviews`.

**`AUTOINCREMENT`** : un identifiant supprimé n'est jamais réutilisé (« stable,
jamais réutilisé »).

**Version 1, sans migration.** Il n'y a rien à faire évoluer : du code de
migration vide ne pourrait pas être testé. La photo `drift_schema_v1.json`
servira de point de départ à la première migration.

**Les tests utilisent une vraie base SQLite en mémoire** (`NativeDatabase.memory()`),
neuve pour chaque test. Un faux objet ne vérifierait ni les `CHECK`, ni les
cascades, ni les transactions. Certains tests écrivent du SQL brut exprès :
les repositories refuseraient ces valeurs avant la base, or c'est la base
seule qu'on veut voir refuser.

### Questions du jury

**Pourquoi un ORM pour six tables ?**
Pour l'évolution : statistiques et profil arrivent en V2. drift apporte des
migrations versionnées et testables, et des requêtes vérifiées à la
compilation. Le SQL reste accessible, et drift est enfermé dans
`lib/data/drift/`.

**Qu'est-ce que le problème N+1 ?**
Lire une liste puis faire une requête par élément : 300 enchaînements, 301
requêtes. Ici, deux requêtes quel que soit le nombre.

**Un ORM, mais pas de DTO : charge-t-on toutes les propriétés à chaque
fois ?**
Les modèles de `lib/models/` sont nos DTO : les lignes de drift (`*Row`,
l'équivalent des entités Doctrine) restent dans `lib/data/drift/`, et le
repository les convertit en `Combo`, sans rien de drift dedans. Pour la
liste, on lit l'enchaînement entier, mais presque tout sert (nom, étapes,
boîte et échéance pour le tri et « À réviser ») ; seules les deux dates de
création et de modification attendent la fiche. Quand une seule colonne
suffit, on fait une projection : `findIdBySignature` ne lit que l'`id`
(`selectOnly`), `countFor` fait un `COUNT`. Un `ComboSummary` pour la liste
ajouterait une classe, une conversion et une requête pour un gain de
quelques microsecondes : la base est locale, petite, sans colonne lourde.
Un DTO de lecture deviendrait utile avec des milliers de lignes, des
colonnes lourdes ou un passage par le réseau.

**Comment prouvez-vous que la base refuse une boîte 7 ?**
Le test T10 l'insère en SQL brut, sans passer par le code Dart : SQLite lève
une erreur.

**Que se passe-t-il si l'enregistrement d'une note échoue à moitié ?**
Rien n'est écrit. Un test crée un déclencheur (*trigger*) qui fait échouer
l'insertion de la note : la boîte de l'enchaînement n'a pas bougé.

**Comment ajouteriez-vous une technique plus tard ?**
Version 2 du schéma : une étape de migration insère la technique (retrouvée
par son `slug` si elle existe déjà) et lui donne une position. drift compare
la base migrée à la photo `drift_schema_v2.json`.

**Pourquoi stocker les dates en texte et pas en nombre ?**
Lisible en ouvrant la base, triable comme du texte, et ISO 8601 est le format
standard. Le fuseau est explicite (`Z`).

## Étape 3 — Écran principal

### Ce qui a été fait

L'écran principal (carte « À réviser », liste, recherche et filtres, quatre
états), le menu latéral, l'écran Techniques et la fiche d'une technique. Les
contrôleurs, la mise en place des services avec `provider`, les couleurs et
icônes des familles, et un jeu de démonstration. L'application ouvre
maintenant la base.

| Fichier | Contenu |
|---|---|
| `lib/main.dart` | **À lire en premier.** Construit la base et les repositories, charge la démo si demandée, lance l'application |
| `lib/ui/app.dart` | `CadenceApp` : déclare les services (`MultiProvider`), le thème, le français |
| `lib/state/load_state.dart` | Les quatre états, en `sealed class` |
| `lib/state/home_controller.dart` | Le contrôleur de l'écran principal : lecture, recherche, chiffres de la carte |
| `lib/ui/home_page.dart` | L'écran principal : `initState`, `dispose`, `switch` sur l'état, menu |
| `lib/state/clock.dart` | L'heure, en service, pour que les tests fixent la date |
| `lib/state/techniques_controller.dart`, `technique_controller.dart` | Les contrôleurs du catalogue et de la fiche technique |
| `lib/ui/techniques_page.dart`, `technique_page.dart` | L'écran Techniques (F24) et la fiche (F25) |
| `lib/ui/widgets/search_filter_bar.dart` | C1 : loupe et familles sur une ligne |
| `lib/ui/widgets/technique_grid.dart` | C2 : la grille de 3 colonnes |
| `lib/ui/widgets/technique_image.dart` | D2 : l'image si elle existe, sinon la pastille de la famille |
| `lib/ui/widgets/combo_tile.dart`, `review_card.dart`, `state_views.dart` | Une ligne de la liste, la carte, les vues des états |
| `lib/ui/format.dart` | Les mots : « Demain », « Dans 5 j », pluriels, côtés et cibles |
| `lib/ui/theme/app_theme.dart` | + `CadenceColors` : les couleurs des six familles |
| `lib/models/dates.dart`, `leitner.dart` | + `daysBetween`, `Leitner.summarize` (calculs purs) |
| `lib/data/repositories.dart`, `drift/drift_combo_repository.dart` | + `findWithTechnique` (F25) |
| `lib/data/demo.dart` | Dix enchaînements de démonstration |
| `test/fakes.dart` | Faux repositories et fausse horloge |
| `test/state/`, `test/ui/` | Contrôleurs, écrans (dont T14), libellés |

### Les notions

**Widget.** Un morceau d'écran décrit en Dart : `Scaffold` contient une
`ListView`, qui contient des `ComboTile`. C'est l'équivalent d'un bloc Twig,
mais écrit en code et imbriqué.

**`build()`.** La méthode qui décrit l'écran à partir des données. Flutter la
rappelle à chaque changement : on ne modifie jamais l'écran à la main, on
change les données et on redécrit. Il n'y a pas de rechargement de page, seul
le morceau concerné se redessine.

**`StatelessWidget` et `StatefulWidget`.** Un `StatelessWidget` n'a que ses
paramètres (`ComboTile` reçoit un enchaînement et l'affiche). Un
`StatefulWidget` possède un objet `State` qui survit aux reconstructions : il
garde ce qui doit vivre aussi longtemps que l'écran (le contrôleur, le champ
de texte).

**`initState()` et `dispose()`.** Appelés une fois, à l'apparition et à la
disparition de l'écran. `initState` crée le contrôleur et lance la lecture ;
`dispose` libère ce qui a été ouvert. Il n'y a pas d'équivalent en PHP, où
tout meurt avec la requête. Un oubli de `dispose` est une fuite de mémoire.

**`ChangeNotifier`.** Le contrôleur. Il garde les données de l'écran et
appelle `notifyListeners()` quand elles changent. Contrairement à un
contrôleur Symfony, qui meurt à la fin de la requête, il vit aussi longtemps
que l'écran.

**`ListenableBuilder`.** Le widget qui écoute le contrôleur : à chaque
`notifyListeners()`, il rappelle son `builder`, et seulement lui.

**`mounted`.** Après un `await`, l'écran a peut-être été fermé. `mounted`
dit s'il est encore là ; sinon, on ne touche plus à rien (R6). Le contrôleur
fait la même vérification avec son propre drapeau `_disposed`.

**`sealed class` et `switch` exhaustif.** Une classe dont toutes les
sous-classes sont dans le même fichier. Le compilateur connaît donc tous les
cas, et un `switch` qui en oublie un ne compile pas.

**Record.** Un groupe de valeurs nommées, sans écrire de classe :
`(due: 2, overdue: 1, total: 3)`. Deux records sont égaux si leurs valeurs le
sont, ce qui facilite les tests.

**Service et injection.** Comme en Symfony, un service est un objet créé une
fois et partagé (un repository, l'horloge). `provider` joue le rôle du
conteneur : `CadenceApp` déclare les services, et un écran demande celui
qu'il lui faut avec `context.read<ComboRepository>()`.

### Les choix

**`provider` pour les services** (au lieu de les passer par les
constructeurs). Avec les constructeurs, chaque écran recevrait les
repositories pour les transmettre aux écrans qu'il ouvre, même s'il ne s'en
sert pas : l'écran Techniques ne lit pas les enchaînements, mais la fiche
technique, qu'il ouvre, en a besoin. Avec `provider`, chaque écran prend
seulement ce qu'il utilise. La V2 (profil, statistiques partagées entre
écrans) le rendra nécessaire : autant le poser maintenant. Il n'y a pas de
perte de performance : les repositories sont de petits objets créés une fois,
et c'est l'ouverture de la base qui coûte, la même dans tous les cas.

`provider` sert seulement aux **services**. L'état d'un écran (sa liste, sa
recherche) reste dans son contrôleur, créé et libéré par l'écran. C'est la
séparation de Symfony entre les services du conteneur et les données d'une
requête.

**Les contrôleurs reçoivent leurs dépendances par le constructeur**
(`HomeController(combos: …, clock: …)`). Ils ne connaissent pas `provider` :
un test les crée avec de faux repositories, sans écran.

**Quatre états en `sealed class`** (au lieu de drapeaux `isLoading`,
`error`…). Avec des drapeaux, on peut se retrouver avec `isLoading` vrai et
une erreur en même temps. Avec la `sealed class`, l'écran est dans un seul
état, et S1 (« une erreur n'est jamais une liste vide ») est garanti par le
type.

**Un contrôleur par écran, avec le filtre dedans.** Le texte cherché et la
famille choisie sont dans le contrôleur, pas dans l'écran : la recherche se
teste sans dessiner d'écran. Le composant C1 ne garde que l'affichage (champ
ouvert ou fermé).

**Recharger explicitement au retour d'un écran** (au lieu des requêtes
« vivantes » de drift). Au retour, l'écran appelle `load()`. Les *streams* de
drift (`watch()`) mettraient la liste à jour toute seule, mais demandent de
s'abonner et de se désabonner, et se combinent mal avec notre lecture en deux
requêtes. On pourra y passer plus tard sans toucher aux écrans. Un rechargement
garde la liste affichée, sans faire clignoter la roue de chargement.

**`Navigator.push`** (au lieu de `go_router`). On empile un écran, le
bouton retour le dépile. Il n'y a ni web ni lien profond, et six écrans :
des routes déclarées (l'équivalent de `routes.yaml`) n'apporteraient rien.

**« Aujourd'hui » recalculé au retour au premier plan.** Une application
laissée ouverte après minuit afficherait de faux chiffres.
`AppLifecycleListener` relit la liste quand l'application revient au premier
plan.

**Une horloge en service** (`Clock`). Le contrôleur ne lit jamais
`DateTime.now()` directement : un test fixe la date au lundi 23 novembre, et
le résultat est le même chaque jour. C'est le `ClockInterface` de Symfony.

**La liste des images lue une fois** (manifeste des assets). On sait
d'avance si `assets/techniques/jab.png` existe, sans tentative ratée ni
clignotement. Tant qu'il n'y a pas d'image, la pastille de la famille
s'affiche partout.

**Couleurs et icônes des familles.** Les couleurs sont dans
`CadenceColors`, une extension du thème, avec une version claire et une
version sombre ; un test vérifie le contraste de chaque icône sur sa pastille.
Les icônes sont prises dans Material. La couleur n'est jamais seule : le nom
de la famille ou de la technique est toujours écrit à côté (V3). Couleurs et
icônes validées sur le Pixel le 22 novembre. Les icônes restent celles de
Material : elles ne sont qu'un repli, en attendant les images.

**Les boutons des étapes futures.** « + », « Ajouter un enchaînement »,
« Commencer » et « Réviser en avance » sont visibles mais désactivés jusqu'aux
étapes 4 et 5. Le menu ne montre que « Techniques ». Aucun bouton ne mène à
un écran vide.

**Un jeu de démonstration.** Dix enchaînements réalistes, avec des
échéances variées (en retard, aujourd'hui, plus tard), écrits par les
repositories, donc soumis à toutes les règles. Chargé seulement avec
`--dart-define=CADENCE_DEMO=true`, et seulement dans une base vide. Il sert à
la relecture et à la démo du 30.

**Les tests d'écran utilisent de faux repositories.** Ils décident de ce
qu'une lecture renvoie, quand elle répond (pour voir la roue) et quand elle
échoue (T14). La vraie base est déjà testée à l'étape 2.

### Questions du jury

**Pourquoi `provider` et pas Riverpod ou BLoC ?**
`provider` est la solution présentée par la documentation de Flutter et
utilisée dans son guide d'architecture. Il fait une seule chose ici : rendre
les services accessibles. Riverpod et BLoC sont des solutions complètes de
gestion d'état, trop lourdes pour six écrans.

**Comment l'écran sait-il qu'il doit se redessiner ?**
Le contrôleur appelle `notifyListeners()`. Le `ListenableBuilder` qui
l'écoute rappelle son `builder`, qui relit l'état et décrit à nouveau la
liste.

**Que se passe-t-il si on quitte l'écran pendant une lecture ?**
`dispose()` libère le contrôleur et lève son drapeau `_disposed`. Quand la
lecture répond, le contrôleur voit le drapeau et ne notifie personne. Un test
le vérifie.

**Comment testez-vous l'état d'erreur ?**
Un faux repository lève une exception. Le test T14 vérifie que le message du
contrôleur s'affiche, pas « Aucun enchaînement », puis que « Réessayer »
affiche la liste.

**Le compteur « À réviser » est-il juste après minuit ?**
Oui : l'application relit la liste quand elle revient au premier plan, et le
jour est recalculé à chaque lecture. Un test avance l'horloge et vérifie les
chiffres.

**Pourquoi le filtre est-il dans le contrôleur et pas dans l'écran ?**
Pour le tester sans écran, et parce que c'est une donnée de l'écran, pas un
détail d'affichage. Le calcul lui-même (`SearchFilter`) est dans `models/`,
testé à l'étape 1.

## Passe de design — « Affiche de combat » (avant l'étape 4)

### Pourquoi

Montrée à quelqu'un, l'application lui a paru « très IA ». Les articles
consultés disent la même chose : cet effet vient des **choix par défaut
jamais remis en question**. Un modèle produit le résultat le plus courant,
et le plus courant finit par se reconnaître. Dans Cadence, on en trouvait
six : la police Roboto avec l'échelle de tailles par défaut, tout dans des
cartes arrondies bordées, les rayons de 16 à 24 px, les filtres en pastilles
avec des bulles pastel, le gros chiffre dans un bloc pastel, et le duo fond
crème et accent doré.

Sources : uxdesign.cc (« How to de-slopify your designs »), The Fountain
Institute (« 7 signs a UI has been vibe coded »), Towards AI (« 10 signs of
AI-generated design »), saasui.design, builtin.com (« AI makes bad design
look good enough »), une discussion Hacker News sur le crème, l'accent
orangé et les serifs, et le guide des thèmes de Flutter.

### Les choix

**Une direction propre au sujet : l'affiche de combat.** Les affiches de
gala et les tableaux de round ont un langage connu : capitales condensées,
contraste fort, chiffres en grand. On garde le noir et or des gants.

**Une police embarquée : Barlow et Barlow Condensed.** La coupe condensée
sert aux titres, aux chiffres, aux libellés et aux onglets ; la coupe normale
au texte courant, pour rester lisible. Les fichiers sont dans l'application
(`assets/fonts/`), parce que Cadence marche hors ligne : le paquet
`google_fonts` les téléchargerait au premier lancement. Licence OFL, citée
dans le README et, à l'étape 6, dans « À propos ».

**Une échelle de tailles à nous**, déclarée une fois dans `AppTheme`
(`TextTheme`), au lieu de celle de Material.

**Un blanc cassé froid** (`#F4F4F2`) à la place de l'ivoire pour le thème
clair, et des gris neutres à la place des bruns. Le thème sombre, validé, ne
change pas.

**Des coins de 4 px partout** (`AppTheme.radius`), 12 px seulement en haut
des feuilles. Un angle presque droit fait « équipement de sport », un grand
rayon fait « application générique ».

**Des listes sans cartes.** Une liste est une liste : des lignes séparées par
des filets, comme un carnet. La seule surface pleine est le tableau de round.

**La carte « À réviser » devient un tableau de round** : un bloc plein,
chiffre en or sur deux chiffres (« 05 »), comme un compteur. Il suit le
thème : gris et or foncé en clair, noir et or en sombre (un bloc noir dans le
thème clair jurait avec le reste, retour d'Antony sur le Pixel). Un lecteur d'écran lit
« 5 à réviser ».

**Des onglets texte à la place des pastilles.** Les familles en capitales,
un trait or sous la famille choisie, un petit carré de couleur devant chaque
nom (la couleur n'est jamais seule, V3). La loupe passe à droite.

**La fiche technique devient une fiche de combattant** : un grand panneau
pour l'image, le nom en grand, puis un tableau Famille · Côté · Cible.

**Les icônes des familles restent** : elles ne sont qu'un repli. Les
illustrations, une fois intégrées, porteront l'identité de l'application.

**Un test de plus pour V4** : écran de 320 px et texte doublé. Il a trouvé
deux débordements (le chiffre de la carte et le titre de section) ; ils sont
corrigés par un seul texte à deux styles (`Text.rich`), qui passe à la ligne.

### Questions du jury

**Pourquoi ne pas avoir gardé Material tel quel ?**
Material est un système, pas une identité : utilisé sans réglage, il donne la
même application que toutes les autres. Les composants restent ceux de
Material (accessibilité, comportements) ; seuls le thème et la mise en page
changent.

**Pourquoi une police embarquée plutôt que `google_fonts` ?**
L'application fonctionne hors ligne : une police téléchargée au premier
lancement manquerait sans réseau. Embarquée, elle coûte environ 400 Ko.

**Comment vérifiez-vous que le texte agrandi ne casse pas l'écran ?**
Deux tests de widget simulent un téléphone de 320 px avec le texte doublé ;
un débordement ferait échouer le test.

**La couleur des familles est-elle accessible ?**
Elle n'est jamais seule : le nom est toujours écrit à côté. Les contrastes
des icônes sur leur carré et du tableau de round sont vérifiés par des tests.

## Étape 4 — Ajouter et corriger

### Ce qui a été fait

Le formulaire (création et modification), la fenêtre de la technique, la
fiche d'un enchaînement, la suppression avec confirmation. « + », les lignes
de la liste et les enchaînements de la fiche technique sont activés. Tests
T12, T13 et T16.

| Fichier | Contenu |
|---|---|
| `lib/state/combo_form_controller.dart` | **À lire en premier.** Ajouter, déplacer, retirer une étape ; `save()` : règles, puis repository |
| `lib/ui/combo_form_page.dart` | Le formulaire : `Form` et `validator`, en-tête épinglé, `PopScope`, message du problème |
| `lib/ui/widgets/step_sheet.dart` | La fenêtre de la technique et son résultat (`StepEdit`) |
| `lib/state/combo_controller.dart`, `lib/ui/combo_page.dart` | La fiche (F16), modifier (F17), supprimer (F18) |
| `lib/ui/home_page.dart`, `technique_page.dart` | Navigation vers le formulaire et la fiche, rechargement au retour |
| `lib/ui/widgets/technique_grid.dart` | + la version *sliver* et les tuiles désactivées à 12 étapes |
| `lib/ui/widgets/fact_row.dart`, `lib/ui/format.dart` | Une ligne « LIBELLÉ valeur » ; `dayLabel`, `stepNumber` |
| `test/fakes.dart` | Les faux repositories savent maintenant écrire, refuser un doublon et échouer |
| `test/state/combo_*`, `test/ui/combo_*` | Contrôleurs, T12, T13, T16, doublon, sortie sans enregistrer, texte doublé |

### Les notions

**`Form`, `TextFormField`, `validator`.** L'équivalent d'un FormType : le
`validator` est la contrainte d'un champ (`Length(max: 60)`), et
`_formKey.currentState!.validate()` joue le rôle de `$form->isValid()`. La
`GlobalKey` donne accès au formulaire depuis l'écran.

**État local.** Le côté et la cible choisis dans la fenêtre ne concernent que
la fenêtre : ils vivent dans son `State` (`setState`). La séquence concerne
les données : elle vit dans le contrôleur.

**Une fenêtre qui renvoie un résultat.** `await showModalBottomSheet(...)`
attend que l'utilisateur choisisse, puis renvoie ce choix : un `StepEdit`
(`SetStep`, `MoveStep`, `RemoveStep`) ou `null` s'il a fermé la fenêtre. De
même, `await Navigator.push(...)` renvoie ce que l'écran suivant passe à
`Navigator.pop(context, résultat)`.

**`try` / `on` / `catch` / `finally`.** `on DuplicateComboException` attrape
une erreur précise, `catch` toutes les autres, `finally` s'exécute dans tous
les cas : c'est là que le bouton est réactivé.

**`PopScope`.** Intercepte le bouton retour d'Android : `canPop: false` tant
que la saisie a changé, et `onPopInvokedWithResult` ouvre alors la
confirmation.

**Sliver.** Un morceau d'une `CustomScrollView`. Le formulaire est une seule
page qui défile : le nom (un morceau simple), l'en-tête épinglé (séquence et
recherche), puis la grille (`SliverGrid`).

**Test de widget.** On lance l'application sur les faux repositories, on
touche (`tap`), on écrit (`enterText`), on attend la fin des animations
(`pumpAndSettle`), puis on vérifie ce qui est à l'écran.

### Les choix

**Un seul écran pour le formulaire**, comme dans `parcours.mmd`. Le nom
défile avec la page ; la séquence et la recherche restent épinglées, pour
voir la séquence grandir en touchant les tuiles. Le test « texte doublé » a
montré que la première version, en colonnes fixes, ne laissait plus de place
à la grille sur un petit écran : d'où la page qui défile.

**« Enregistrer » en bas, en pleine largeur.** À portée de pouce, et il ne
déborde plus de la barre du haut avec un texte agrandi.

**La fenêtre de la technique en feuille du bas.** Le même composant sert à
ajouter (F9) et à corriger une étape (F10, avec Avant, Après, Retirer). Une
technique sans choix (une défense, un déplacement) est ajoutée directement.

**Déplacer par Avant / Après** plutôt que par glisser-déposer : simple à
tester, conforme à la spécification. Le glisser-déposer pourra venir plus
tard.

**Un `ComboFormController` pour créer et modifier.** Il garde la séquence et
l'enregistrement ; le nom reste dans le champ de texte, comme un champ de
formulaire Symfony, et lui est passé à l'enregistrement. Les problèmes sont
une `sealed class` (`InvalidCombo`, `DuplicateCombo`, `SaveFailed`) : le
contrôleur dit *quoi*, l'écran choisit les mots.

**Le doublon vérifié à l'enregistrement.** Le repository lève
`DuplicateComboException` : la règle n'est écrite qu'à un endroit, et la base
garde le dernier mot. Le message reste affiché (une SnackBar disparaîtrait)
avec « Ouvrir l'existant », qui ouvre la fiche par-dessus le formulaire,
puis ferme le formulaire quand on quitte la fiche (voir la question du jury
sur `pushReplacement`).

**Après l'enregistrement**, le formulaire se ferme avec l'enchaînement en
résultat ; la liste (ou la fiche) se recharge, et la liste affiche
« Enregistré · à réviser demain ».

**Les dates avec `intl`** (« 24 novembre 2026 »). Le paquet est déjà présent
avec `flutter_localizations`, qui charge les noms des mois en français.

**Supprimer après une confirmation qui nomme l'enchaînement**, sans
« Annuler » après coup : c'est ce que demandent F18 et T16. Annuler, ou
toucher hors de la fenêtre, ne change rien.

**Toucher une technique ferme le clavier.** Sinon, à la fermeture de la
fenêtre, Flutter rendait le focus au dernier champ actif (le nom) et le
clavier se rouvrait à chaque coup choisi (retour d'Antony sur le Pixel). Le
formulaire appelle `unfocus()` avant d'ouvrir la fenêtre ; un test le
vérifie.

**Avant / arrière, pas gauche / droite** (vérifié et confirmé par Antony).
Les clubs disent souvent « crochet du gauche », mais les textes de la FFKMDA
et de la FFBoxe disent « bras avant / bras arrière » : c'est le seul
vocabulaire juste quelle que soit la garde (pour un gaucher, le crochet avant
est son crochet du droit).

**Les faux repositories écrivent vraiment** (en mémoire) : un test vérifie le
parcours complet, de la tuile touchée à la ligne dans la liste.

### Questions du jury

**Comment empêchez-vous deux enregistrements sur deux appuis rapides ?**
`save()` ne fait rien si un enregistrement est en cours, et le bouton est
désactivé pendant ce temps. Un test retient la réponse du faux repository et
vérifie qu'une seule écriture a lieu.

**Où est la validation ?**
À trois niveaux : le `validator` du champ nom (comme une contrainte de
FormType), `ComboRules.validate` dans le contrôleur (2 à 12 étapes), et la
base (signature unique, `CHECK`). Les deux premiers donnent un message, la
base est le filet de sécurité.

**Que se passe-t-il si l'enregistrement échoue ?**
L'écran reste ouvert, la séquence et le nom sont conservés, un message invite
à réessayer (F13). Testé avec un faux repository qui lève une erreur.

**Pourquoi le côté choisi n'est-il pas dans le contrôleur ?**
Il ne compte qu'avant « Ajouter » : c'est un état d'affichage de la fenêtre.
Le contrôleur ne reçoit que l'étape finie.

**Pourquoi « crochet avant » et pas « crochet du gauche » ?**
C'est le vocabulaire des glossaires de la FFKMDA et de la FFBoxe, et il reste
juste en fausse garde. Un réglage de garde qui traduirait en gauche / droite
pourrait venir plus tard, sans toucher à la base.

**Comment testez-vous la suppression ?**
T16 : on ouvre la fiche, « Supprimer », « Annuler » : rien ne change ; puis
« Supprimer » et confirmer : la fiche se ferme et la liste est vide.

**Pourquoi pas `pushReplacement` pour « Ouvrir l'existant » ?**
C'était le premier choix : remplacer le formulaire par la fiche. Défaut
trouvé pendant le parcours guidé : `pushReplacement` donne tout de suite le
résultat du formulaire à l'écran d'en dessous. L'accueil relisait donc sa
liste dès l'ouverture de la fiche, et un enchaînement supprimé depuis cette
fiche restait affiché. Désormais la fiche est empilée (`push`) ; quand on la
quitte, le formulaire se ferme (`pop`) et l'accueil relit sa liste au bon
moment. `pop` ne consulte pas `PopScope` : la saisie est abandonnée
volontairement. Le test F12 supprime l'enchaînement depuis la fiche et
vérifie que la liste est vide au retour.

## Deuxième passe d'interface — aérer et marquer les actions

### Pourquoi

Retour d'Antony sur le Pixel, après l'étape 4 : en thème clair le noir est
trop dur ; les boutons d'action ne ressortent pas ; l'or devrait être plus
lumineux sans briller ; tout est serré, on est submergé d'informations ; il
manque un logo.

### Les choix

**Une encre anthracite** (`#2B2D30`) au lieu du presque-noir : le contraste
reste très au-dessus de 4,5:1, sans la dureté du noir sur blanc.

**Deux ors, chacun son rôle.** L'or des **actions** (`primaryContainer`,
`#E0B54D`), mat et lumineux, porte toujours un texte foncé : boutons
principaux, bouton « Ajouter ». Il est le même dans les deux thèmes, pour
qu'une action se reconnaisse partout. L'or du **texte** (`primary`) reste
plus profond en clair (`#85620F`), car un or vif ne se lit pas en petit sur
fond clair (2,2:1).

**Des boutons d'action francs** : 52 px de haut, texte gras, dans le thème
une fois pour toutes. Le bouton « + » passe en or. Un libellé « Ajouter »
a été essayé puis retiré à la demande d'Antony : le « + » seul suffit et
charge moins l'écran.

**De l'air.** Une marge de page de 24 px (`AppTheme.gutter`) au lieu de 16,
des lignes de liste plus hautes, des sections plus espacées, des miniatures
plus petites (24 px) : moins de choses se battent pour l'œil.

**Les écrans s'arrêtent au-dessus de la barre de navigation d'Android**,
qu'elle soit en gestes ou en boutons. Android dessine désormais
l'application sous cette barre (*edge-to-edge*) ; un seul `SafeArea` dans
`MaterialApp.builder` (`lib/ui/app.dart`) protège tous les écrans d'un coup,
au lieu d'y penser dans chacun. Un test simule une barre de 48 px.

**Les tests d'écran tournent sur un écran de Pixel** (412 × 915) : avec plus
d'espace, certains éléments sortaient de l'écran de test par défaut
(800 × 600), qui ne ressemble à aucun téléphone. Les tests « texte doublé »
gardent leur écran de 320 px.

**Le logo : la paire de gants du personnage**, noire et or, en vectoriel plat
sans reflet, généré avec Gemini (logo, et icône de l'application qui tient
dans le cercle central). Intégration à l'étape 6.

## Le logo et les premières images

### Ce qui a été fait

Antony a généré le logo (une affiche : la paire de gants suspendue, anthracite
et or, rayons) et cinq images de famille (poings, défenses, pieds,
déplacements, genoux). Elles remplacent les pastilles d'icônes ; les coudes
gardent la pastille en attendant leur image.

**Le 24, les images de famille sont retirées** (remise à zéro voulue par
Antony, la démarche sera redéfinie) : toutes les familles reprennent leur
pastille, sans changer de code, grâce au repli D2.

**Le 24 au soir, 9 images de techniques** générées par Antony sont
intégrées : `jab`, `cross`, `hook`, `elbow_downward`, `high_guard`, `high_kick`, `middle_kick`, `knee_straight`, `knee_clinch`. Elles sont détourées par un petit script (fond papier
reconnu par sa clarté, poussière et ombres sous les pieds retirées, seule la
plus grande forme gardée), puis réduites en PNG 512 × 512 transparents,
environ 130 Ko chacune (1,3 Mo en tout). Les 32 autres techniques gardent
leur pastille : là encore, aucun code ne change (D2).

**Finalement, une image par famille** (choix d'Antony, le 24 tard) : les 9
images de techniques sont remplacées par 6 images de famille, du même
personnage (poings, coudes, pieds, genoux, défenses, déplacements),
détourées par le même script et enregistrées en `family_<famille>.png`
(environ 130 Ko chacune, 780 Ko en tout). Toutes les techniques ont ainsi
une image, celle de leur famille ; une image propre à une technique pourra
s'ajouter plus tard (`<slug>.png`) et passera devant, toujours sans code.
Les JPG d'origine restent hors du projet, sinon ils seraient embarqués
dans l'APK.

| Fichier | Contenu |
|---|---|
| `assets/brand/poster.webp`, `gloves.webp` | L'affiche, et son recadrage carré sur les gants |
| `android/app/src/main/res/` | Icône de l'application : adaptative (Android 8+) et classique |
| `lib/ui/widgets/brand.dart` | `BrandMark` (les gants) et `BrandPoster` (l'affiche) |
| `lib/ui/widgets/sunburst.dart` | Les rayons de l'affiche, dessinés en code (`CustomPainter`) |
| `lib/ui/widgets/technique_image.dart` | Repli : image de la technique, sinon de la famille, sinon pastille |

### Les choix

**Le logo à quatre endroits** : à côté de « CADENCE » dans la barre de
l'écran principal, en grand en tête du menu (l'affiche), sur l'écran vide (le
premier écran d'un nouvel utilisateur), et comme icône de l'application.

**Une icône adaptative.** Depuis Android 8, le lanceur découpe l'icône
(cercle, carré arrondi) : les gants sont placés dans la zone sûre centrale,
sur l'anthracite du logo, pour ne jamais être rognés.

**Les images détourées** par un petit script (remplissage depuis les bords :
le blanc qui touche le bord devient transparent, le contour noir du dessin
arrête le remplissage). Sans cela, un carré blanc apparaîtrait en thème
sombre.

**Un repli à trois niveaux (D2)** : image de la technique si elle existe,
sinon celle de sa famille, sinon la pastille. L'application reste cohérente
avec 0, 5 ou 41 images.

**La palette sombre reprise du logo** : l'anthracite légèrement bleuté de
l'affiche (`#1F2324`) remplace le brun-noir, le blanc cassé de ses rayons
devient l'encre. L'or des actions était déjà celui du logo.

**Les rayons de l'affiche derrière la carte « À réviser »**, très discrets,
dessinés en code : ils relient l'écran principal au logo sans image de plus.

**Retours sur le Pixel.**
- L'affiche du menu coupait un gant : un bandeau de hauteur fixe dans une
  image plus haute que large. Elle est maintenant **carrée, calée en bas**
  (`AspectRatio(1)`, `Alignment.bottomCenter`) : les gants restent entiers
  quelle que soit la largeur du menu, seul le haut du lacet est coupé. Sur un
  petit écran avec un grand texte, le menu défile.
- On ne voyait pas que les onglets de filtre défilent. Deux indices : les
  bords **s'estompent** du côté où des onglets sont cachés (`ShaderMask`), et
  l'onglet touché **glisse vers le milieu** (`Scrollable.ensureVisible`), ce
  qui fait apparaître les suivants. Pas de flèche : elle aurait pris la place
  d'un onglet et ajouté un bouton de plus.
- Les couleurs des familles : un essai avec des couleurs vives, un lavis
  et un liseré autour de chaque image était trop criard ; le liseré seul,
  en teintes sourdes, n'a pas convaincu non plus. On garde les **teintes
  sourdes** (brique, ocre, bleu acier, violet éteint, vert sauge,
  bleu-vert, plus claires en thème sombre), une par famille, pour l'icône
  de repli et le carré de l'onglet. Les images sont posées **directement
  sur le fond**, sans cadre ni carré gris : détourées, elles respirent
  mieux, et elles sont un peu plus grandes (80 px dans la grille, 220 px
  sur la fiche technique).

### Questions du jury

**Les images sont-elles générées par IA ?**
Oui, avec Gemini, à partir d'une fiche personnage commune pour garder le
même combattant d'une image à l'autre ; c'est dit dans le README. Le code de
l'application, lui, ne dépend pas de leur présence (repli D2).

**Qu'est-ce qu'un `CustomPainter` ?**
Un objet qui dessine sur un canevas avec des lignes et des formes, comme un
`<canvas>` en HTML. Les rayons sont calculés (angle, longueur des tirets) au
lieu d'être une image, donc nets à toutes les tailles et dans les deux
thèmes.

**Comment l'application sait-elle qu'il reste des onglets à droite ?**
La liste qui défile envoie des notifications (`ScrollMetricsNotification` au
premier affichage, `ScrollUpdateNotification` à chaque défilement) avec sa
position et sa longueur. La barre les écoute avec un `NotificationListener`
et estompe un bord tant que la position n'est pas au bout de ce côté.

**Pourquoi 3:1 pour les couleurs des familles, et pas 4,5:1 ?**
L'icône et le carré de l'onglet ne sont pas du texte. Les règles d'accessibilité (WCAG
1.4.11) demandent 3:1 pour les éléments graphiques, 4,5:1 pour le texte.
Le seuil plus bas laisse plus de choix de teintes ; le test de contraste le
vérifie pour chaque famille, sur le fond et sur les surfaces, dans les deux
thèmes. Et le nom de la famille est toujours écrit (V3).

## Étape 5 — Séance vocale

### Ce qui a été fait

« Commencer » et « Réviser en avance » ouvrent la séance (E4) : la voix dit
chaque coup de l'enchaînement, 12 fois, en trois paliers ; puis la note est
demandée et enregistrée tout de suite ; à la fin de la série, « Séance
terminée » et « Continuer ». Pause, reprise, « Passer à la note »,
« Arrêter », pause en arrière-plan, écran allumé, voix indisponible (S4).
Tests T7 et T15.

| Fichier | Contenu |
|---|---|
| `lib/models/drill.dart` | **À lire en premier.** Les paliers (`Pace`), la liste de ce que dit la voix (`Cue`), la série de 5 : des fonctions pures |
| `lib/state/session_controller.dart` | Les phases de la séance (`sealed class`), la boucle de la voix, pause, note, « Continuer » |
| `lib/state/speaker.dart`, `screen_awake.dart` | Les contrats de la voix et de l'écran allumé ; `SilentSpeaker` pour S4 |
| `lib/platform/` | Leurs versions Android : `ClipSpeaker` (voix enregistrée, `just_audio`), `VoiceClips` (le fichier de chaque mot), `WakelockScreenAwake` ; connues du seul `main.dart` |
| `assets/voice/` | Les annonces enregistrées : `full/` (89, lentes), `short/` (51, moyennes et rapides) |
| `lib/ui/session_page.dart` | L'écran : tableau de round, séquence, boutons, note, fin |
| `lib/ui/home_page.dart`, `widgets/review_card.dart` | Le bouton de la carte est activé (`_startSession`) |
| `test/platform/voice_clips_test.dart` | Chaque annonce, à chaque palier, a son fichier, et chaque fichier est une annonce |
| `test/models/drill_test.dart`, `test/ui/session_page_test.dart` | T7 ; T15, pause, arrière-plan, S4, « Continuer », note refusée, écran allumé |

### Les notions

**Plugin natif.** `just_audio` et `wakelock_plus` ne sont pas du Dart pur :
ils appellent Android (le lecteur audio, l'écran). Dans un test,
Android n'existe pas : tout appel planterait.

**Contrat et faux, encore.** D'où `Speaker` et `ScreenAwake`, deux
interfaces, comme `ComboRepository`. `main.dart` branche les versions
Android (`lib/platform/`), les tests branchent `FakeSpeaker` (il note ce
qu'on lui fait dire) et `FakeScreenAwake`. Comme `lib/data/drift/` pour
drift, `lib/platform/` enferme les plugins.

**`Timer`.** Une minuterie : `Timer(durée, fonction)` appelle la fonction une
fois la durée écoulée ; `cancel()` l'en empêche. Le silence entre deux coups
est un `Timer`, annulé à la pause et dans `dispose()`.

**`Completer`.** Fabrique un `Future` et décide quand il se termine. Il
transforme un `Timer` en quelque chose qu'on peut `await` : « attendre
500 ms ».

**Une boucle `async` qu'on peut interrompre.** `_run()` dit les coups l'un
après l'autre (`await speak`, puis `await` le silence). Pour l'arrêter, on
n'a pas besoin de la tuer : `_halt()` augmente un compteur (`_runs`), comme
`_loads` à l'étape 3 ; après chaque `await`, la boucle compare son numéro au
compteur et s'arrête s'il a changé.

**Le temps truqué des tests.** Un test de widget tourne dans un temps
factice : `tester.pump(const Duration(minutes: 2))` avance l'horloge de deux
minutes d'un coup et déclenche toutes les minuteries en chemin. Les 24 coups
d'un enchaînement sont dits en quelques millisecondes réelles.

### Les choix

**Une voix enregistrée plutôt que la synthèse du téléphone.** La première
version utilisait `flutter_tts` (la synthèse d'Android). Essayée sur le
Pixel, la voix ne plaisait pas, et elle dépend des voix installées sur
chaque téléphone. Comme l'application ne dit que des annonces connues d'avance, chacune a
été enregistrée une fois avec la synthèse vocale de Gemini, dans
`assets/voice/` (140 fichiers `.ogg`, 840 Ko).

Un premier essai enregistrait chaque mot à part (41 techniques, 2 côtés,
3 cibles) et les jouait à la suite : « Crochet » « arrière » « au corps ».
Sur le Pixel, on entendait trois mots collés, pas une phrase : chaque mot
avait l'intonation d'une fin de phrase. D'où une phrase entière par
annonce, dite d'un trait : 89 lentes (`full/`), 51 courtes (`short/`).
Deux générations séparées donnaient une voix inégale (« Teep » dit
« tip » puis « type ») : tout a été refait **en une seule génération**,
avec une consigne de style et la prononciation des termes anglais écrite
dans la consigne. Un petit script Python a découpé les 140 annonces sur les
silences et les a nommées dans l'ordre de la liste
(`docs/VOIX_PHRASES.md`) ; une page d'écoute a servi à les vérifier une à
une.

Avantages : la même voix partout, hors ligne, plus besoin de `spokenName`
ni de déclarer le moteur vocal dans le manifeste. Limite : une nouvelle
technique demandera de nouveaux enregistrements, et un test le rappelle.

**Défaut connu** : même en une seule génération, la voix dérive. À partir de
l'annonce 75 (« Teep arrière au corps »), elle change de timbre et le reste
jusqu'à la fin. Gardée pour l'instant ; la reprise est prévue en lots
courts, avec des annonces étalon déjà bonnes en tête de chaque lot pour
comparer les prises (`docs/VOIX_PHRASES.md`).

Les annonces sont compressées en Opus (`.ogg`, 32 kbit/s, mono, avec
`ffmpeg`) : 840 Ko au lieu de 6,5 Mo en `.wav`, sans différence audible
pour une voix. Android lit l'Opus nativement.

**Le contrat `Speaker` a payé.** Passer de la synthèse aux enregistrements
n'a changé ni le contrôleur ni les tests de la séance : seule la classe
branchée dans `main.dart` (`ClipSpeaker` au lieu de `TtsSpeaker`) et la
signature de `speak`, qui reçoit maintenant l'étape (`ComboStep`) plutôt
qu'un texte, pour trouver son fichier.

**La fin de l'enregistrement fait avancer les répétitions.** On joue un
coup, on attend la fin (`play()` se termine à la fin du fichier), on fait
le silence du palier, puis le coup suivant. « Superman punch » prend plus de
temps que « Jab » sans rien calculer. Une minuterie fixe aurait pu couper
un mot long.

**Les paliers raccourcissent l'annonce, comme un entraîneur** (idée
d'Antony). Lent : « Crochet arrière au corps » ; moyen : « Crochet corps »
(la cible en un mot, comme on le dit en salle) ; rapide : « Crochet ». Le
rythme monte parce qu'il y a moins à dire, sans déformer la voix ; et au
palier rapide, il faut se souvenir soi-même du côté et de la cible, ce qui
fait travailler la mémoire (le principe même de la répétition espacée).
La règle est une fonction pure, `Drill.call(step, pace)`, testée seule
(T7).

**La cible est toujours dite quand elle a été choisie**, même la cible par
défaut : « Crochet avant à la tête », pas seulement « Crochet avant ». Sans
personne pour montrer, un débutant doit savoir où frapper (idée d'Antony
après l'essai sur le Pixel). La règle D3 change donc, **à l'écran comme à
la voix** : une seule règle (`ComboStep.saidTarget`), le libellé affiché
est exactement l'annonce du palier lent. Les libellés sont un peu plus
longs ; les tests à 320 px avec le texte doublé (V4) passent toujours.

**Les paliers changent aussi un peu la vitesse et le silence.** Lent :
vitesse enregistrée (×1), 500 ms entre les coups ; moyen : ×1,1 et 250 ms ;
rapide : ×1,2 et 100 ms ; 1 s entre deux répétitions pour souffler. Valeurs
figées dans `Pace` (D10). `setSpeed` de `just_audio` accélère sans rendre la
voix aiguë. Réglées à l'oreille sur le Pixel : la première version
(vitesses ×0,8 / ×1 / ×1,2, silences de 900 à 200 ms) manquait de vitesse ;
avec les annonces courtes, une légère accélération suffit.

**« Commencer » avant chaque enchaînement.** La voix ne part pas d'elle-même :
l'écran montre la séquence et attend un appui (phase `Ready`). On a le temps
de lire l'enchaînement, de poser le téléphone et de se mettre en garde. Après
une note, l'enchaînement suivant attend aussi : on vient de toucher l'écran,
on n'est pas en garde. Demandé par Antony après l'essai sur le Pixel.

**Le déroulé est une donnée.** `Drill.cues(steps)` renvoie d'avance la liste
de tout ce que la voix dira (répétition, étape, palier, texte, silence). Le
contrôleur n'a plus qu'à la parcourir avec un index : la pause garde
l'index, la reprise repart du coup coupé. Le calcul se teste sans attendre
(T7).

**Les phases en `sealed class`** : `Preparing`, `SessionFailed`, `Ready`
(l'enchaînement affiché, la voix attend), `Drilling`
(coup en cours, en pause ou non), `Grading`, `Finished`. L'écran fait un
`switch` exhaustif, comme sur `LoadState`.

**S4 est un `Speaker` comme un autre.** Si la voix plante (un fichier
illisible, le lecteur audio en échec), le contrôleur la remplace par
`SilentSpeaker`, qui ne dit rien mais prend à peu près le temps du mot. Les
répétitions défilent au même rythme, un bandeau le dit.

**Une pause n'est pas une panne** (défaut trouvé sur le Pixel). Pause coupe
la voix (`stop()`) ; si la coupure tombe pendant le chargement d'une
annonce, `just_audio` lève une erreur « Loading interrupted ». La séance la
prenait pour une panne et passait sans le son. Corrigé à deux endroits :
`ClipSpeaker` traite cette erreur comme une annonce terminée, et le
contrôleur ignore toute erreur d'une annonce déjà coupée (son numéro de
passage, `run`, n'est plus le bon). Un test le rejoue avec un faux qui
échoue quand on le coupe.

**Aucune nouvelle requête.** « Commencer » prend `findDue(today)`,
« Réviser en avance » `findAll()` (déjà triée par échéance), puis les 5
premiers. Les enchaînements notés pendant la séance sont écartés de
« Continuer » (`Drill.series`), sinon « Réviser en avance » les reproposerait.
La taille 5 est une constante jusqu'au réglage de l'étape 6.

**Pause en arrière-plan, reprise à la main.** `AppLifecycleListener(onHide:)`
met en pause ; la voix ne repart pas seule, sinon elle parlerait dans une
poche.

**« Arrêter » sans confirmation.** Chaque note est enregistrée dès qu'elle est
donnée (F22) : rien n'est perdu. Le bouton retour fait la même chose :
fermer l'écran libère le contrôleur, qui coupe la voix.

**Trois boutons de note de même poids**, chacun avec l'échéance qu'il donne
(« Demain », « Dans 3 j »…) : la note reste un choix honnête, pas un bouton
mis en avant.

### Questions du jury

**Comment testez-vous la voix sans l'entendre ?**
Avec un faux `Speaker` qui note chaque phrase et son palier. T15 vérifie
24 phrases pour un enchaînement de 2 coups, 8 par palier, dans l'ordre, puis
la note enregistrée et la liste relue.

**Que se passe-t-il si on reçoit un appel pendant la séance ?**
L'application est cachée : la séance se met en pause et la voix s'arrête.
Au retour, « Reprendre » redit le coup coupé.

**Et si la voix ne peut pas être jouée ?**
La séance l'annonce et continue sans le son (S4). Testé avec un faux
`Speaker` qui répond « indisponible ».

**D'où vient la voix, et en avez-vous le droit ?**
Elle a été générée avec la synthèse vocale de Gemini : un enregistrement
par mot, découpé dans une seule génération : une voix de synthèse, pas
celle d'une personne. Les conditions d'utilisation de Google pour le contenu généré
s'appliquent ; elles sont à relire avant une publication sur le Play Store.

**Pourquoi ne pas avoir gardé la synthèse du téléphone ?**
Elle change d'un téléphone à l'autre, demande des voix installées, et
prononçait mal plusieurs noms (« Djab » écrit pour « Jab »). Le vocabulaire
étant fermé, des enregistrements sont plus simples et plus fiables.

**Pourquoi un contrat pour l'écran allumé, une seule ligne de code ?**
Parce que cette ligne appelle Android et planterait dans chaque test de la
séance. Le contrat coûte dix lignes et rend la séance testable.

**Pourquoi la note est-elle enregistrée tout de suite ?**
Pour qu'un arrêt en cours de séance ne perde rien (F22). Si l'écriture
échoue, la note est redemandée ; testé avec un faux repository qui refuse.

## Audit avant l'étape 6 — code propre, performances, sécurité

Demandé par Antony avant les réglages : relire tout le code selon *Clean
Code* (Robert C. Martin), vérifier les performances sans tomber dans la
suroptimisation, et faire un point sécurité, même pour une application hors
ligne.

### Code propre : les commentaires

**Règle retenue** : un commentaire ne dit que ce que le code ne peut pas
dire. Le livre le résume ainsi : un commentaire compense un échec à
s'exprimer dans le code. Les commentaires pédagogiques écrits pour Antony
(« comme `find($id)` en Symfony », « un `Completer` fabrique un Future… »)
étaient utiles pour apprendre, mais ils vivent maintenant dans ce document
et dans les parcours guidés, plus dans le code.

- **Avant** : 644 lignes de commentaire dans `lib/`.
- **Après** : une soixantaine. Chacune explique un « pourquoi » invisible :
  - un comportement surprenant d'une bibliothèque (`just_audio` laisse le
    lecteur « en lecture » à la fin d'un fichier ; SQLite ignore les clés
    étrangères sans `PRAGMA`) ;
  - une contrainte (6 décimales pour que les dates se trient ; le jour
    compté en UTC à cause de l'heure d'hiver) ;
  - un garde-fou (relire la liste au retour, ne pas relancer la voix dans
    une poche).
- Les renvois aux exigences (F21, D10…) ont quitté le code : ils restent
  dans les **noms des tests**, qui font le lien avec la spécification.
- Les contrats de repository gardent seulement les exceptions levées
  (`Throws [NotFoundException]`) : c'est ce que l'appelant ne peut pas
  deviner.

### Code propre : les noms

| Avant | Après | Pourquoi |
|---|---|---|
| `Drill.call` | `Drill.announcement` | `call` est un nom spécial en Dart (objet appelable) et ne dit rien |
| `perPace` | `repetitionsPerPace` | « par palier » de quoi ? |
| `Cue.index` | `Cue.stepIndex` | l'index de l'étape, pas de la répétition |
| `visible` | `visibleCombos`, `visibleTechniques` | ce qui est visible |
| `_loads`, `_runs` | `_loadCount`, `_runCount` | un compteur, pas une liste |
| `run != _runs` | `_isStale(run)` | la condition se lit comme une phrase |
| `_cue`, `_index`, `current` | `_cueIndex`, `_comboIndex`, `currentCombo` | |
| `ahead` | `reviewAhead` | « Réviser en avance » |
| `editing`, `saving`, `paused`, `failed` | `editedCombo`, `isSaving`, `isPaused`, `hasFailed` | un booléen commence par `is` / `has`, un objet porte un nom |
| `add`, `move`, `remove` (formulaire) | `addStep`, `moveStep`, `removeStep` | le verbe et son objet |
| `_halt`, `_wait`, `_pick`, `_play`, `_begin` | `_interrupt`, `_waitSilence`, `_pickSeries`, `_startSeries`, `_prepareCurrentCombo` | |
| `byId`, `idBySlug`, `_load` | `techniquesById`, `techniqueIdsBySlug`, `_findWhere` | |
| `(c) =>`, `(s) =>`, `(t) =>`, `(n) =>` | `(combo) =>`, `(step) =>`, `(technique) =>`, `(notification) =>` | jamais une lettre, sauf `a`, `b` dans un comparateur |
| `reviews` (nombre) | `reviewCount` | un nombre, pas une liste |
| `_content()` | `_buildList()` | une méthode qui construit commence par un verbe |

### Performances

Ce qui était déjà bien fait :

- **Pas de requête N+1** : la liste lit tous les enchaînements, puis toutes
  leurs étapes, en deux requêtes, quel que soit leur nombre.
- **Le catalogue est lu une fois** et gardé en mémoire par le repository.
- **La base tourne hors du fil de l'écran** : `drift_flutter` ouvre SQLite
  dans un *isolate* séparé, l'interface ne gèle jamais pendant une requête.
- **Les étapes sont écrites en un seul lot** (`batch`), dans une transaction.
- **La grille des techniques est paresseuse** (`GridView.builder`) : seules
  les tuiles visibles existent.
- **Un seul lecteur audio**, réutilisé pour chaque annonce.

Ce qui a été corrigé :

- **La liste de l'accueil construisait toutes les lignes d'un coup**
  (`ListView(children: [...])`), avec jusqu'à six miniatures chacune. Elle
  passe en `CustomScrollView` + `SliverList.separated` : seules les lignes
  visibles sont construites, comme la grille.
- **Les images étaient décodées en 512 × 512** pour être affichées en 24 à
  48 px. `cacheWidth` les décode à la taille affichée : avec les 41 images
  de techniques à venir, la mémoire passe d'environ 40 Mo à quelques Mo.
- **Le résumé de la carte était calculé deux fois** par construction : une
  seule fois maintenant.

Ce qui n'a pas été fait, volontairement :

- **Pas d'index sur `due_on`** : SQLite lit une table de quelques centaines
  de lignes plus vite qu'il ne consulterait un index. À reconsidérer
  au-delà de quelques milliers.
- **Le filtre de recherche est recalculé à chaque construction** : sur
  quelques centaines d'enchaînements, c'est imperceptible ; le mettre en
  cache ajouterait de l'état à synchroniser pour rien.

### Sécurité

Une application hors ligne a peu de surface d'attaque, mais pas aucune.

Ce qui est sûr :

- **Aucun accès réseau** : le manifeste principal ne demande pas
  l'autorisation `INTERNET` (seules les versions de développement l'ont,
  pour le débogage). Vérifié sur l'APK final (`aapt dump permissions`) :
  Android lui interdit tout accès à Internet, les données ne peuvent pas
  partir. Le lecteur audio ajoute `ACCESS_NETWORK_STATE`, qui permet
  seulement de savoir si le téléphone est connecté, sans rien envoyer ; on
  le garde, le retirer pourrait faire planter le lecteur.
- **Pas d'injection SQL** : drift écrit des requêtes paramétrées ; la seule
  requête écrite à la main est une constante (`PRAGMA foreign_keys = ON`).
- **Des données validées deux fois** : par `ComboRules` (2 à 12 étapes, nom
  de 60 caractères au plus), puis par les contraintes de la base (`CHECK`,
  `UNIQUE`, clés étrangères).
- **Pas de chemin de fichier construit depuis une saisie** : les fichiers de
  voix et d'images viennent des noms du catalogue et des énumérations,
  jamais de ce que tape l'utilisateur.
- **Un seul point d'entrée exporté** : l'écran de lancement. Pas de lien
  profond, pas de WebView, pas de service exposé aux autres applications.
- **Les secrets de signature ne sont pas versionnés** : `key.properties`,
  `*.jks` et `*.keystore` sont dans `.gitignore`, et aucun n'est suivi par
  Git (vérifié).
- **Le jeu de démonstration** ne peut être activé qu'à la compilation
  (`--dart-define`), jamais dans l'APK publié.

Ce qui a été corrigé :

- **Les journaux d'erreur** : `debugPrint` écrit aussi dans les journaux du
  téléphone en version finale. Il est coupé en version finale
  (`kReleaseMode`), une ligne dans `main.dart`.
- **La CI** reçoit seulement le droit de lire le dépôt
  (`permissions: contents: read`) : une action compromise ne pourrait rien
  écrire.

Ce qui reste à décider ou à faire à l'étape 7 :

- **La sauvegarde Android** (`allowBackup`) : par défaut, Android
  sauvegarde la base dans le compte Google de l'utilisateur. C'est pratique
  pour changer de téléphone, mais « vos données restent sur cet appareil »
  (F29) deviendrait inexact. **Décidé à l'étape 6** : la sauvegarde est
  gardée, et « À propos » le dit.
- **La signature** de l'APK final utilise encore la clé de débogage ; la
  vraie clé arrive à l'étape 7, hors du dépôt.
- **L'obfuscation** du code Dart (`--obfuscate --split-debug-info`) à la
  construction de la version finale.
- **La taille de l'APK final** : 64 Mo, car il contient le code machine de
  trois processeurs. Un APK par processeur (`--split-per-abi`) ou un
  *App Bundle* ramène le téléchargement autour de 20 Mo.
- **Les actions de la CI** sont désignées par leur version majeure
  (`@v4`) ; les épingler par leur empreinte (SHA) protégerait d'une version
  modifiée après coup.

### Questions du jury

**Pourquoi si peu de commentaires ?**
Parce que les noms disent déjà ce que fait le code. Un commentaire qui
répète le code vieillit mal : on change le code, on oublie le commentaire,
et il ment. Les commentaires restants expliquent un pourquoi que le code ne
peut pas dire.

**Votre application est hors ligne : quels risques de sécurité ?**
Peu, et ils sont traités : pas d'accès réseau (vérifié sur l'APK), pas
d'injection SQL, des données validées deux fois, pas de secret dans le
dépôt. Le point ouvert est la sauvegarde Android dans le compte Google.

**Comment avez-vous vérifié les performances ?**
En cherchant les trois pièges classiques de Flutter et des bases de
données : les requêtes N+1, les listes construites en entier, les images
décodées trop grandes. Les deux derniers ont été corrigés.

## Étape 6 — Réglages et finitions

### Ce qui a été fait

Un écran **Paramètres** (thème, taille de la séance) et un écran **À
propos** (version, confidentialité, origines, licences), ouverts depuis le
menu. Les sept décisions ci-dessous ont été validées par Antony avant le
code.

| Fichier | Ce qu'il faut regarder |
|---|---|
| `lib/models/settings.dart` | **D'abord.** `Settings` (thème, taille de séance, bornes 1 à 20) et `ThemeChoice` : du Dart pur, sans Flutter |
| `lib/state/settings_controller.dart` | Le seul contrôleur partagé par toute l'application. Il applique un choix, puis l'enregistre |
| `lib/data/repositories.dart` | Le contrat `SettingsRepository` : `load()` et `save()` |
| `lib/data/preferences/preferences_settings_repository.dart` | La version `shared_preferences`, et le repli sur les valeurs par défaut |
| `lib/main.dart` | Les réglages lus **avant** `runApp`, la version, la licence OFL |
| `lib/ui/app.dart` | `MaterialApp` écoute le contrôleur : `themeMode` change partout d'un coup |
| `lib/ui/settings_page.dart`, `lib/ui/about_page.dart` | Les deux écrans |
| `lib/state/session_controller.dart` | `seriesSize` : la séance prend la taille réglée |
| `test/state/settings_controller_test.dart`, `test/data/preferences_settings_repository_test.dart`, `test/ui/settings_page_test.dart` | Bornes, enregistrement, relecture après redémarrage, valeurs invalides, thème appliqué, taille de séance, « À propos », V4 à 320 px |

### Les notions

**`shared_preferences`.** Un petit stockage clé-valeur fourni par Android
(un fichier XML privé à l'application). Fait pour quelques réglages, pas
pour des données : les enchaînements restent dans SQLite. On utilise
`SharedPreferencesAsync`, l'API récente : chaque lecture et chaque écriture
va au stockage, sans copie en mémoire à tenir à jour.

**Un contrôleur partagé.** Jusqu'ici, chaque écran créait son contrôleur et
le libérait en partant. Le thème, lui, concerne toute l'application :
`SettingsController` est créé une fois dans `main.dart` et déclaré avec
`ChangeNotifierProvider`. `MaterialApp` l'écoute (`ListenableBuilder`) :
quand on choisit « Sombre », tout l'arbre est redessiné avec l'autre thème.

**`RadioGroup`.** Depuis Flutter 3.35, les boutons radio se regroupent dans
un `RadioGroup` qui porte la valeur choisie et le changement, au lieu de
les répéter sur chaque bouton.

### Les choix

**`shared_preferences` plutôt qu'une table drift.** Deux valeurs simples ne
justifient pas une migration de schéma (version 2). Comme pour la voix, le
paquet est derrière un contrat, avec un faux pour les tests.

**Lu avant `runApp`.** Sinon l'application s'ouvrirait un instant en clair
avant de passer en sombre. La lecture prend quelques millisecondes.

**Appliqué, puis enregistré.** L'écran change tout de suite, sans attendre
le disque. Si l'écriture échoue, le choix reste valable jusqu'au prochain
lancement : rien de grave pour un réglage, pas la peine d'inquiéter
l'utilisateur.

**Une valeur stockée n'est pas crue sur parole.** Un thème inconnu ou une
taille hors de 1 à 20 (fichier abîmé, ancienne version) redonne la valeur
par défaut au lieu de planter.

**Trois lignes à cocher pour le thème**, séparées par des filets comme nos
listes, plutôt qu'un bouton segmenté Material, le choix « par défaut » qui
fait générique.

**Un compteur − 05 + pour la taille de séance**, avec le chiffre en Barlow
Condensed comme le tableau de round. Un curseur de 1 à 20 rend difficile de
tomber pile sur une valeur. Les boutons se désactivent aux bornes.

**`package_info_plus` pour la version.** Elle vient de l'APK installé, donc
de `pubspec.yaml` : jamais de constante oubliée lors d'une nouvelle version.
Lue une fois dans `main.dart` et passée aux écrans dans `AppInfo`, ce qui
garde l'écran testable sans le plugin.

**La page de licences de Flutter** (`showLicensePage`) liste déjà toutes
les licences des paquets ; la licence OFL des polices y est ajoutée dans
`main.dart` (`LicenseRegistry`), depuis `assets/fonts/OFL.txt`.

**La sauvegarde Android est gardée** (choix d'Antony) : en changeant de
téléphone, l'utilisateur retrouve ses enchaînements. « À propos » le dit
honnêtement : les données restent sur le téléphone, l'application n'a pas
accès à Internet, mais Android peut les copier dans le compte Google si la
sauvegarde est activée. Au retour d'une sauvegarde, la base revient avec la
même version de schéma : drift l'ouvre normalement, et une version plus
récente de l'application la migrerait comme d'habitude.

### Questions du jury

**Pourquoi le thème n'a-t-il pas son contrôleur dans l'écran Paramètres ?**
Parce qu'il concerne toute l'application, pas un écran : `MaterialApp` doit
l'écouter. Un contrôleur créé dans l'écran disparaîtrait en le quittant.

**Que se passe-t-il si le fichier des réglages est abîmé ?**
Les valeurs inconnues ou hors bornes redonnent les valeurs par défaut :
testé avec un thème « neon » et une taille de 99.

**Vous dites que les données restent sur le téléphone, mais il y a la
sauvegarde Google ?**
L'application elle-même ne peut rien envoyer : elle n'a pas l'autorisation
Internet. La sauvegarde est faite par Android, si l'utilisateur l'a
activée, comme pour toutes ses applications ; l'écran « À propos » le dit.

## Étape 7 — Livraison

### Ce qui a été fait

L'APK final est signé avec la clé personnelle d'Antony, et un tag `v…`
construit et publie la release sur GitHub sans intervention. Les huit
décisions ci-dessous ont été validées par Antony avant le code.

| Fichier | Ce qu'il faut regarder |
|---|---|
| `android/app/build.gradle.kts` | **D'abord.** `key.properties` lu s'il existe, la configuration `release`, et le garde-fou qui arrête la construction sans clé |
| `.github/workflows/release.yml` | Le workflow de livraison : contrôles, version du tag, clé reconstituée, APK, release |
| `.github/workflows/ci.yml` | `workflow_call` : la livraison réutilise les contrôles. Actions épinglées par empreinte |
| `README.md` | La version finale : installation, captures, 3 choix, limites, origines |
| `.git/info/exclude` | `docs/*` puis `!docs/CHOIX.md` : ce fichier entre dans le dépôt |
| `screenshots/` | Sept captures prises sur le Pixel avec le jeu de démonstration, réduites à 540 px de large |

### Les notions

**Signer un APK.** Android n'installe une mise à jour que si elle est signée
par la même clé que la version déjà installée : la signature prouve que la
mise à jour vient du même auteur. La clé est un fichier *keystore* (`.jks`)
protégé par un mot de passe. Perdue, elle empêche pour toujours de mettre à
jour l'application installée ; publiée, elle permet à n'importe qui de
publier une fausse mise à jour. Elle reste donc hors du dépôt, avec une
copie de secours.

**`key.properties`.** Un petit fichier texte, jamais versionné
(`android/.gitignore`), qui dit à Gradle où trouver la clé et avec quels mots
de passe. Gradle le lit à la construction de la version finale.

**Les secrets GitHub.** Des valeurs chiffrées rangées dans les réglages du
dépôt. Un workflow les reçoit en variables d'environnement ; elles ne
paraissent ni dans le code ni dans les journaux (GitHub les masque). La clé,
un fichier binaire, y est rangée encodée en base64 (du texte), puis décodée
par le workflow.

**Un tag.** Une étiquette posée sur un commit (`v1.0.0`). Un tag *annoté*
porte aussi un message : il sert de notes de version. Pousser le tag
déclenche le workflow de livraison.

**Un workflow réutilisable.** `ci.yml` déclare `workflow_call` : le workflow
de livraison l'appelle comme une fonction, au lieu de recopier les
contrôles. La release n'est construite que si les contrôles passent
(`needs: checks`).

### Les choix

**Pas de repli sur la clé de débogage.** Sans `key.properties`, la
construction de la version finale s'arrête avec un message clair (tâche
`preReleaseBuild`). Un APK signé par erreur avec la clé de débogage
s'installerait, puis ne pourrait jamais être mis à jour par la vraie.

**`gh release create`, pas une action tierce.** L'outil `gh` est déjà sur
les machines de GitHub. Le seul workflow qui a le droit d'écrire
(`contents: write`, sur le seul job qui publie) n'exécute pas de code
d'un inconnu.

**Les actions épinglées par empreinte (SHA).** Un tag comme `@v4` peut être
déplacé par l'auteur de l'action, ou par quelqu'un qui lui a volé son
compte. Une empreinte désigne un contenu précis, qui ne peut plus changer.
Le commentaire `# v4.4.0` garde la version lisible.

**Le tag doit correspondre à `pubspec.yaml`.** Sinon la release `v1.0.1`
contiendrait un APK qui se dit `1.0.0` dans « À propos ».

**Un APK par processeur (`--split-per-abi`).** Un APK universel contient le
code machine de trois familles de processeurs (64 Mo). Séparés, ils pèsent
entre 22 et 26 Mo. Le README indique `arm64-v8a`, qui convient aux
téléphones récents. L'*App Bundle* ne sert qu'à un store, hors du périmètre.

**Pas d'obfuscation.** Le code est public sur GitHub : le rendre illisible
dans l'APK ne cache rien, et rendrait les traces d'erreur illisibles.

**Java 21 dans le workflow** (`actions/setup-java`), la version actuelle à
long terme, plutôt que celle présente par hasard sur la machine de GitHub.

**Des captures authentiques**, prises sur le téléphone avec le jeu de
démonstration, plutôt que des maquettes : le jury voit l'application telle
qu'elle est. Réduites à 540 px, trois fois la largeur affichée par le README.

**CHOIX.md versionné à son chemin**, avec en tête la clé des codes
d'exigences (F, D, S…), puisque la spécification reste hors du dépôt.

### Ajouté pendant la livraison : de l'enchaînement à la technique

Sur la fiche d'un enchaînement, toucher une étape ouvre la fiche de sa
technique (`lib/ui/combo_page.dart`, `_openTechnique`). La navigation va
maintenant dans les deux sens : la fiche technique ouvrait déjà les
enchaînements qui l'utilisent. Proposé par Antony en regardant les captures.

**Seulement sur la fiche.** Dans le formulaire, toucher une étape sert déjà
à la corriger ; pendant la séance, on ne doit pas pouvoir en sortir par
erreur ; dans la liste de l'accueil, la ligne entière ouvre l'enchaînement.

**Le cas limite.** Fiche de A → Jab → « Utilisée dans » → A de nouveau →
supprimer. En revenant, la première fiche de A montrerait un enchaînement
qui n'existe plus. Elle est donc relue au retour, comme après « Modifier » :
le contrôleur affiche alors « Cet enchaînement n'existe plus. ». La relecture
ne fait pas clignoter l'écran : un état déjà prêt ne repasse pas par le
chargement.

**L'alignement.** Les lignes « Utilisée dans » de la fiche technique
reprenaient la ligne de l'accueil (`ComboTile`), qui ajoute sa propre marge
de 24 px à celle de la page : 48 px en tout. `ComboTile` reçoit maintenant
`horizontalPadding`, à zéro quand la page a déjà sa marge. Un test vérifie
que les lignes commencent au même endroit que « FAMILLE ».

### La revue finale

Avant de publier, une relecture de tout `lib/`, de Gradle et des workflows,
à la recherche de défauts réels. Cinq ont été trouvés et corrigés ; aucun ne
perdait de données.

| Défaut | Correction | Test |
|---|---|---|
| Une pause pile entre le chargement d'une annonce et sa lecture laissait passer la voix : un lecteur arrêté recharge son clip quand on lui demande de jouer | `ClipSpeaker` numérote chaque annonce ; `stop()` la rend périmée, et elle ne joue plus (même principe que `_runCount` dans `SessionController`). Le lecteur peut être remplacé par un faux | `test/platform/clip_speaker_test.dart` |
| Une valeur du mauvais type dans les réglages (ancienne version, sauvegarde restaurée) faisait échouer la lecture avant `runApp` : l'application ne s'ouvrait plus | Chaque lecture qui échoue donne la valeur par défaut (`_readOrNull`) | Thème enregistré comme nombre, taille comme texte |
| Un enchaînement supprimé affichait « Une erreur est survenue » et un « Réessayer » qui ne pouvait pas réussir | Introuvable devient l'état `Empty`, affiché comme « Enchaînement supprimé », sans bouton | Contrôleur et fiche |
| `create()` renvoyait un `Combo` qui partageait la liste, modifiable, du formulaire | Une copie non modifiable (`List.unmodifiable`) | Modifier la liste après coup ne change pas le `Combo` |
| La liste était lue en deux requêtes : une modification glissée entre les deux aurait mélangé l'ancien et le nouvel état | Les deux lectures dans une transaction | Pas de test : il faudrait provoquer le hasard |

**Question du jury : comment avez-vous testé un plugin natif ?**
`ClipSpeaker` reçoit son `AudioPlayer` par le constructeur (le vrai par
défaut). Le test lui passe un faux qui ne joue rien et compte les appels à
`play()` : on vérifie l'ordre des opérations sans téléphone.

### Ce qu'Antony fait lui-même

Créer la clé (`keytool`), écrire `android/key.properties`, ranger la clé en
lieu sûr, créer les quatre secrets (`ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`),
faire la recette sur l'APK final, pousser, poser et pousser le tag. Claude ne
lit jamais la clé ni `key.properties`.

### Questions du jury

**Où est votre clé de signature ?**
Sur ma machine, avec une copie de secours, et dans les secrets GitHub pour
la construction automatique. Jamais dans le dépôt : `.gitignore` exclut
`key.properties`, `*.jks` et `*.keystore`.

**Que se passe-t-il si vous perdez la clé ?**
Les téléphones qui ont Cadence ne pourront plus recevoir de mise à jour :
il faudrait désinstaller (et perdre les données) puis installer une
application signée autrement. D'où la copie de secours.

**Pourquoi pas le Play Store ?**
Hors du périmètre de la V1 : compte développeur, fiche, politique de
confidentialité, examen. La release GitHub suffit pour un APK installé à la
main.

**Comment savez-vous que la release correspond au code ?**
Elle est construite par GitHub depuis le commit du tag, après les mêmes
contrôles que la CI (format, analyse, tests), et refusée si le tag ne
correspond pas à la version de `pubspec.yaml`.
