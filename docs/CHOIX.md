# CHOIX — Cadence

Les décisions du projet, rangées par thème, chacune avec sa raison. Le
README donne la vue d'ensemble ; ce document explique le pourquoi.

Les noms des tests portent les codes de la spécification (F12, D3, T7…),
restée hors du dépôt.

## 1. Le besoin et le périmètre

Un pratiquant de sport de combat note, après le cours, les enchaînements
vus, puis les révise au bon moment, dictés à voix haute. D'où trois
priorités : **noter vite**, **réviser au bon moment**, **s'entraîner sans
regarder l'écran**.

**Hors ligne, Android seulement.** Le cours demande un APK ; une application
de salle doit marcher sans réseau. Le projet est créé avec
`--platforms android` : pas de dossiers iOS, web ou bureau jamais utilisés.

**Un seul écran principal.** Les règles Android réservent la barre du bas à
3 à 5 destinations d'importance égale. Cadence a deux actions principales,
réviser et ajouter : une carte « À réviser » avec « Commencer » et un bouton
flottant « + ». Le catalogue, rarement ouvert, va dans le menu latéral, avec
les Paramètres et « À propos ».

**Le vocabulaire de la discipline.** Les noms suivent le glossaire technique
de la FFKMDA et l'usage des clubs : poings, coudes et genoux en français,
coups de pied en anglais (Low, Middle, High kick). Le Front kick (percuté) et
le Teep (poussé) sont deux techniques. **Avant / arrière, pas gauche /
droite** : les clubs disent souvent « crochet du gauche », mais c'est faux
pour un gaucher ; « bras avant / bras arrière » est juste quelle que soit la
garde.

**Un catalogue fixe de 41 techniques.** C'est un référentiel, inséré dans la
base au premier lancement. Ajouter ses propres techniques est prévu en V1.2 :
chacune demande ses enregistrements de voix (voir § 6).

**Identifiant `io.github.antony35.cadence`.** Un identifiant d'application
est un nom de domaine à l'envers ; sans domaine personnel, celui de la page
GitHub est la convention.

## 2. L'architecture

```
ui/  →  state/  →  data/ (contrats)  →  data/drift/ (SQLite)
                   models/ (règles pures, utilisées par tous)
```

**Des couches qui ne se parlent que par contrats.** Un écran ne connaît que
son contrôleur ; un contrôleur ne connaît que des contrats
(`ComboRepository`, `Speaker`, `Clock`…), des interfaces sans code.
L'implémentation est choisie une seule fois, dans `main.dart`. Les tests
branchent des faux à la place : base en mémoire, voix muette, date fixe.

**Les règles métier dans `models/`, sans Flutter ni base.** Libellés,
validation, doublon, boîtes de Leitner, déroulé de la séance : des fonctions
pures, testées sans écran ni attente.

**Les bibliothèques enfermées.** drift ne sort pas de `lib/data/drift/`,
`shared_preferences` de `lib/data/preferences/`, `just_audio` et
`wakelock_plus` de `lib/platform/`. Changer de bibliothèque ne toucherait
qu'un dossier.

**`provider` pour les services.** Les services (repositories, horloge, voix)
sont créés une fois dans `main.dart` et déclarés dans `CadenceApp` ; chaque
écran prend ce qu'il utilise (`context.read<ComboRepository>()`). Passés par
les constructeurs, ils traverseraient des écrans qui ne s'en servent pas :
l'écran Techniques ne lit pas les enchaînements, mais la fiche technique
qu'il ouvre en a besoin. La V2 (profil, statistiques partagées) le rendra
nécessaire. Aucun coût : ce sont de petits objets créés une fois.

**Un contrôleur par écran** (`ChangeNotifier`), créé dans `initState`, libéré
dans `dispose`. `provider` ne sert qu'aux services : l'état d'un écran (sa
liste, sa recherche) reste dans son contrôleur. Les contrôleurs reçoivent
leurs dépendances par le constructeur et ne connaissent pas `provider` : un
test les crée sans écran. Seule exception, `SettingsController`, partagé par
toute l'application (§ 5).

**Les états en `sealed class`.** Une lecture est `Loading`, `Ready`, `Empty`
ou `Failed`, jamais deux à la fois ; avec des drapeaux `isLoading` et
`error`, on pourrait avoir les deux. Le `switch` de l'écran doit traiter
chaque cas, sinon il ne compile pas : une erreur ne s'affiche jamais comme
une liste vide. Même principe pour les phases de la séance et les problèmes
du formulaire (`InvalidCombo`, `DuplicateCombo`, `SaveFailed`) : le
contrôleur dit *quoi*, l'écran choisit les mots.

**L'heure est un service** (`Clock`). Aucun `DateTime.now()` hors de lui :
un test fixe la date au lundi 23 novembre, et donne le même résultat chaque
jour.

**`Navigator.push`, pas `go_router`.** On empile un écran, le retour le
dépile. Sans web ni lien profond, des routes déclarées n'apporteraient rien.

**Relire au retour, pas de requêtes « vivantes ».** Au retour d'un écran, la
page appelle `load()`. Les *streams* de drift (`watch()`) mettraient la
liste à jour seuls, mais demandent abonnement et désabonnement, et se
combinent mal avec la lecture en deux requêtes. Une relecture garde
l'affichage : la roue de chargement ne clignote pas. Elle couvre aussi les
allers-retours entre fiches : un enchaînement modifié ou supprimé depuis la
fiche d'une technique est relu en revenant sur sa propre fiche, qui affiche
alors « Enchaînement supprimé ».

**Après un `await`, vérifier qu'on est encore là.** L'écran a pu être fermé
pendant la lecture : `mounted` côté écran, `_disposed` côté contrôleur. Une
lecture plus ancienne ne remplace jamais une plus récente (`_loadCount`).

## 3. Les modèles et les règles

**Des objets immuables.** Un objet immuable ne change plus une fois créé :
tous ses champs sont `final`. Pour changer la boîte d'un enchaînement après
une note, on ne touche pas à l'objet : on en fabrique un nouveau, identique
sauf la boîte (`combo.copyWith(box: 3)`). Pourquoi ? Le même enchaînement
est lu par plusieurs morceaux de l'application à la fois : la liste, la
fiche, la séance. Si l'un d'eux pouvait le modifier, les autres verraient
leurs données changer sans l'avoir demandé, et ce genre de bug est très
difficile à retrouver. Avec un objet immuable, ce que l'on a entre les mains
reste vrai tant qu'on le garde.

**`freezed` en mode « classe classique ».** Un objet immuable a besoin de
quatre méthodes qu'on écrit toujours de la même façon : `==` (deux
enchaînements aux mêmes valeurs sont égaux), `hashCode` (qui va avec `==`),
`copyWith` (la copie modifiée) et `toString` (un affichage lisible pour
déboguer). Écrites à la main, chacune énumère tous les champs : le jour où
l'on ajoute un champ, on oublie de l'ajouter dans l'une d'elles, et rien ne
le signale. `freezed` les génère à partir de la classe. On garde une classe
Dart ordinaire, lisible, et seul le code répétitif est généré.

**`final` ne protège pas le contenu d'une liste.** Un champ `final` ne peut
pas pointer vers une autre liste, mais on peut encore ajouter ou retirer des
éléments dans la liste qu'il désigne. La revue finale a trouvé ce cas : un
enchaînement tout juste créé gardait la liste d'étapes du formulaire, que le
formulaire pouvait encore modifier. Le repository lui donne maintenant une
copie non modifiable (`List.unmodifiable`) : toute tentative de
modification échoue tout de suite au lieu de passer en silence.

**Une technique s'identifie par son `slug`** (`low_kick`). Le catalogue est
écrit dans le code avant d'exister en base : il n'a pas encore d'`id`. L'`id`
et la `position` restent dans `data/`.

**Un `Combo` existe toujours en base.** Le formulaire ne manipule qu'un nom
et une liste d'étapes ; quitté, il n'enregistre rien. `Combo.id` n'est donc
jamais `null`.

**Valider renvoie une erreur, ne plante pas.** Pendant la saisie, un
enchaînement incomplet est normal : `ComboRules.validate` renvoie
`tooFewSteps`… ou `null`. En revanche, une étape avec un côté que la
technique refuse lève une `ArgumentError` : l'écran ne le propose jamais,
c'est donc un bug.

**Zéro doublon, par une signature lisible** : `jab:lead:head|low_kick:rear:-`.
Douze étapes au plus, donc un texte court ; lisible quand on cherche un bug ;
stable, puisque le `slug` ne change jamais. Le nom ne compte pas : deux
séquences identiques sont un doublon.

**La cible est dite et affichée dès qu'il y avait un choix**, même par
défaut : « Crochet avant à la tête ». Sans personne pour montrer, un débutant
doit savoir où frapper. Une seule règle (`ComboStep.saidTarget`) sert à
l'écran et à la voix.

**La boîte de Leitner.** Six boîtes, à 1, 3, 7, 14, 30 et 60 jours.
Difficile → boîte 1 ; Correct → boîte suivante ; Facile → deux plus loin.
`box` et `due_on` sont stockés dans l'enchaînement alors qu'on pourrait les
recalculer depuis les révisions : « quoi réviser aujourd'hui » reste une
requête simple. Les intervalles sont fixes : un réglage n'apporterait rien à
la V1.

**Les dates sans bibliothèque.** Un jour est un `DateTime` local à minuit.
`addDays` reconstruit la date (`DateTime(a, m, j + n)`) au lieu d'ajouter
`n × 24 h` : le jour du passage à l'heure d'hiver dure 25 h ; l'écart en
jours se compte en UTC pour la même raison. Aucune fonction de `models/` ne
lit l'horloge : le jour est passé en paramètre. Règle générale : un paquet
quand il remplace beaucoup de code répétitif ou risqué (`freezed`, drift),
du code maison quand c'est dix lignes. `intl` ne sert qu'à **afficher** les
dates en français.

**La recherche ignore les accents**, par une petite table (é→e, ç→c, œ→oe),
et cherche dans le nom comme dans les techniques ; le filtre par famille se
combine avec elle.

## 4. Les données

**SQLite.** Cadence marche sans réseau ni serveur : il faut une base
**embarquée**, un fichier sur le téléphone, pas une base serveur comme
PostgreSQL. Et les données sont **liées** : un enchaînement a des étapes,
chaque étape pointe vers une technique. « Les enchaînements qui contiennent
un Low kick » est une jointure, ce que SQL sait faire ; un fichier JSON se
réécrirait en entier à chaque modification.

**Six tables, quatre principes.**
1. **Une case, une valeur.** Les côtés et cibles acceptés par une technique
   sont dans des tables de liaison, pas dans un texte « lead,rear ».
2. **La base refuse les valeurs inconnues.** Chaque colonne à valeurs fixes
   a une contrainte `CHECK`, construite depuis l'énumération Dart
   (`isOneOf(family, Family.values)`) : la liste n'est écrite qu'une fois.
   Pas de table `sides` ou `grades` : elles servent quand la liste change
   sans toucher au code, et ici chaque valeur déclenche du code.
3. **Zéro doublon garanti par la base** : la signature est `UNIQUE`.
4. **Des identifiants entiers** (`AUTOINCREMENT`, jamais réutilisés). Tout
   est local : un UUID ne servirait qu'à synchroniser plusieurs appareils.

**La position dans le catalogue (1 à 41) est unique** et suit l'ordre des
familles. Un seul `ORDER BY position` range le catalogue ; un tri par
famille rangerait les codes par ordre alphabétique (`defense`, `elbow`…).

**drift plutôt que `sqflite`.** `sqflite` exécute du SQL écrit à la main,
sous forme de texte : une faute de colonne n'apparaît qu'à l'exécution.
drift décrit les tables en Dart, vérifie les requêtes à la compilation et
versionne le schéma : `drift_schemas/` garde une photo de chaque version, et
la V2 migrera la base des téléphones sans perte. Coût : un second générateur
de code et un temps d'apprentissage. Les classes générées (`*Row`) restent
dans `data/drift/` et sont converties en modèles : les écrans ne voient
jamais drift.

**Version 1, sans migration.** Il n'y a rien à faire évoluer : du code de
migration vide ne pourrait pas être testé. La photo de la version 1 servira
de point de départ.

**Quatre contrats de repository** : le catalogue, les enchaînements, les
révisions, les réglages. Une note modifie aussi l'enchaînement (boîte,
échéance) : `ReviewRepository.record` le fait dans une transaction.

**Deux requêtes pour relire les enchaînements, pas N+1.** Une pour les
enchaînements, une pour toutes leurs étapes, rangées ensuite en Dart ; deux
requêtes qu'il y en ait 3 ou 300, dans une même transaction pour qu'une
modification ne se glisse pas entre elles. Une seule jointure aurait répété
chaque enchaînement jusqu'à 12 fois.

**Les index utiles seulement.** `findDue` lit les enchaînements à réviser
grâce à l'index sur `due_on` (un test vérifie avec `EXPLAIN QUERY PLAN` que
SQLite l'utilise) ; les étapes et les révisions sont indexées par leur clé
étrangère. L'ordre des listes (`due_on, box, created_at, id`) est celui de
`Leitner.compare` ; un test compare les deux.

**Modifier = effacer les étapes puis les réécrire**, dans une transaction.
Comparer les listes serait fragile : déplacer une étape décale toutes les
positions, et `(combo_id, position)` est la clé primaire. L'`id`, la
création, la boîte, l'échéance et les révisions sont conservés.

**Le doublon est vérifié avant d'écrire**, dans la transaction ; l'exception
porte l'`id` de l'enchaînement existant, pour « Ouvrir l'existant ». La
contrainte `UNIQUE` reste en filet de sécurité, mais son message n'est pas
lu : drift travaille dans un fil séparé (*isolate*) et emballe l'erreur
SQLite autrement que dans les tests.

**Une écriture qui ne touche aucune ligne lève `NotFoundException`** :
modifier ou supprimer un enchaînement disparu ne passe pas en silence.

**Les instants en UTC, les jours en local.** `created_at` :
`2026-11-24T20:47:12.345678Z`, relu en heure locale ; UTC n'est jamais
ambigu, même la nuit où 2 h 30 existe deux fois. `due_on` : `2026-11-27`,
car un jour n'existe qu'en heure locale. Toujours 6 décimales : sinon
`12.000Z` se rangerait après `12.000500Z` dans un tri de texte.

**Une note ne change pas `updated_at`**, qui dit quand l'enchaînement a été
**modifié** ; les dates de révision sont dans `reviews`.

**Les clés étrangères activées à chaque ouverture** (`PRAGMA foreign_keys`) :
SQLite les ignore sinon. Supprimer un enchaînement supprime ses étapes et
ses révisions (`ON DELETE CASCADE`).

**Les réglages dans `shared_preferences`**, pas dans une table : deux
valeurs simples ne justifient pas une version 2 du schéma. Une valeur
stockée n'est pas crue sur parole : inconnue, hors bornes ou du mauvais type
(ancienne version, sauvegarde restaurée), elle redonne la valeur par défaut.
Ils sont lus avant l'ouverture de l'application, qui sinon s'ouvrirait un
instant en clair avant de passer en sombre.

## 5. L'interface

**Une identité : l'affiche de combat.** Montrée à quelqu'un, la première
version a paru « très IA ». Cet effet vient des **choix par défaut jamais
remis en question** : police Roboto, tout dans des cartes arrondies, filtres
en pastilles, gros chiffre dans un bloc pastel, fond crème et accent doré.
Cadence prend le langage des affiches de gala et des tableaux de round :
capitales condensées, contraste fort, chiffres en grand, noir et or des
gants.
- **Barlow et Barlow Condensed**, embarquées (`assets/fonts/`) parce que
  l'application est hors ligne ; la coupe condensée pour les titres,
  chiffres et onglets, la normale pour le texte. Licence OFL, affichée dans
  « À propos ».
- **Des coins de 4 px** : un angle presque droit fait « équipement de
  sport », un grand rayon fait « application générique ».
- **Des listes sans cartes**, des lignes séparées par des filets, comme un
  carnet. La seule surface pleine est le tableau de round.
- **La carte « À réviser » en tableau de round** : le chiffre en or sur deux
  chiffres (« 05 »), les rayons de l'affiche derrière, très discrets,
  dessinés en code. Un lecteur d'écran lit « 5 à réviser ».
- **Des onglets texte plutôt que des pastilles** pour les familles, un trait
  or sous la famille choisie. Les bords s'estompent du côté où des onglets
  sont cachés, et l'onglet touché glisse vers le milieu : on comprend qu'ils
  défilent.
- **La fiche technique en fiche de combattant** : l'image en grand, le nom,
  puis Famille · Côté · Cible.

**Les couleurs dans un seul fichier** (`app_theme.dart`). Les écrans lisent
le thème : changer une couleur ne touche aucun écran.
- **Clair** : blanc cassé froid `#F4F4F2`, encre anthracite `#2B2D30` (pas
  de noir pur, trop dur).
- **Sombre** : l'anthracite bleuté du logo `#1F2324`.
- **Deux ors, deux rôles.** L'or des **actions** (`#E0B54D`, mat), toujours
  avec un texte foncé, le même dans les deux thèmes : une action se
  reconnaît partout. L'or du **texte** est plus foncé en clair, car un or
  vif ne se lit pas en petit sur fond clair (2,2:1).
- **Une teinte sourde par famille** (brique, ocre, bleu acier…), pour le
  carré de l'onglet et la pastille de repli. La couleur n'est jamais seule :
  le nom est toujours écrit à côté.
- **Des tests de contraste** calculent le rapport WCAG de chaque paire texte
  / fond et exigent 4,5:1 dans les deux thèmes : une couleur changée par
  erreur est vue avant l'utilisateur.

**De l'air.** Une marge de page de 24 px, des lignes hautes, des miniatures
de 24 px : moins de choses se battent pour l'œil. Les actions principales
font 52 px de haut, en or, en bas de l'écran, à portée de pouce. Le « + »
est seul, sans libellé.

**Le formulaire sur un seul écran qui défile.** Le nom défile avec la page ;
la séquence et la recherche restent épinglées en haut, pour voir la
séquence grandir en touchant les tuiles ; « Enregistrer » est en bas. La
première version, en colonnes fixes, ne laissait plus de place à la grille
sur un petit écran avec un texte agrandi.

**La fenêtre de la technique en feuille du bas**, la même pour ajouter et
pour corriger une étape (côté, cible, Avant, Après, Retirer). Une technique
sans choix est ajoutée directement. Déplacer par Avant / Après plutôt que
par glisser-déposer : simple et testable. Toucher une tuile ferme le
clavier, sinon il se rouvrait à chaque coup choisi.

**Le doublon dit, pas caché.** Le message reste affiché (une notification
passagère disparaîtrait) avec « Ouvrir l'existant ».

**Quitter sans enregistrer demande confirmation** (`PopScope`) ; supprimer
aussi, en nommant l'enchaînement. Pas d'« Annuler » après coup.

**La navigation va dans les deux sens** entre enchaînements et techniques :
la fiche technique liste les enchaînements qui l'utilisent, et toucher une
étape d'un enchaînement ouvre sa technique. Seulement sur la fiche : dans le
formulaire, toucher une étape sert à la corriger, et pendant la séance on ne
doit pas pouvoir en sortir par erreur.

**Les images.** Une image par famille, du même personnage, détourée par un
script (le fond qui touche le bord devient transparent) pour ne pas faire de
carré blanc en thème sombre, et posée sur le fond sans cadre. **Un repli à
trois niveaux** : l'image de la technique si elle existe, sinon celle de sa
famille, sinon une pastille de couleur. L'application reste cohérente avec
0, 6 ou 41 images, sans changer de code. La liste des images est lue une
fois : pas de tentative ratée ni de clignotement. Les images sont décodées à
la taille affichée, pas en 512 px.

**Le logo**, une paire de gants noire et or : dans la barre de l'accueil, en
tête du menu, sur l'écran vide (le premier qu'un nouvel utilisateur voit) et
comme icône. L'icône est adaptative : les gants restent dans la zone sûre,
jamais rognés par la forme du lanceur.

**Les réglages.** Le thème (Système, Clair, Sombre) en trois lignes à
cocher plutôt qu'un bouton segmenté générique ; la taille de la séance en
compteur − 05 +, plus précis qu'un curseur de 1 à 20. Un choix s'applique
tout de suite, puis s'enregistre : si l'écriture échoue, il reste valable
jusqu'au prochain lancement. `SettingsController` est le seul contrôleur
partagé : `MaterialApp` l'écoute, et tout l'écran change de thème d'un coup.

**« À propos »** : la version lue dans l'APK installé (`package_info_plus`,
jamais une constante oubliée), la confidentialité, l'origine des images et
de la voix, et les licences (la page de Flutter, avec celle des polices).

**Les écrans s'arrêtent au-dessus de la barre de navigation d'Android.**
Android dessine l'application dessous (*edge-to-edge*) ; un seul `SafeArea`
dans `MaterialApp.builder` protège tous les écrans d'un coup.

**Un jeu de démonstration** de dix enchaînements, aux échéances variées,
écrit par les repositories (donc soumis à toutes les règles), chargé
seulement avec `--dart-define=CADENCE_DEMO=true` et dans une base vide :
jamais dans l'APK publié.

## 6. La voix et la séance

**Une voix enregistrée plutôt que la synthèse du téléphone.** La synthèse
dépend des voix installées : voix, accent et prononciation de « Low kick »
ou « Teep » changent d'un téléphone à l'autre. L'application ne dit que des
annonces connues d'avance : chacune a été enregistrée une fois, avec la
synthèse vocale de Gemini, en Opus (140 fichiers, 840 Ko au lieu de 6,5 Mo
en WAV). La même voix partout, hors ligne. Limite : une nouvelle technique
demande ses enregistrements, et un test vérifie que chaque annonce, à chaque
palier, a son fichier.

**Une phrase entière par annonce**, pas des mots collés : « Crochet »
« arrière » « au corps » joués à la suite sonnaient comme trois fins de
phrase. Et **une seule génération** pour les 140 annonces, avec la
prononciation des termes anglais écrite dans la consigne : deux générations
séparées donnaient deux voix.

**Les paliers raccourcissent l'annonce, comme un entraîneur.** Douze
répétitions : 4 lentes (« Crochet arrière au corps »), 4 moyennes
(« Crochet corps »), 4 rapides (« Crochet »). Le rythme monte parce qu'il y a
moins à dire ; au palier rapide, il faut se souvenir soi-même du côté et de
la cible, ce qui fait travailler la mémoire. La voix accélère un peu (×1,
×1,1, ×1,2, sans devenir aiguë) et le silence entre les coups raccourcit
(500, 250, 100 ms), avec 1 s entre deux répétitions. Valeurs réglées à
l'oreille sur le téléphone.

**La fin de l'annonce fait avancer.** On joue le coup, on attend la fin du
fichier, puis le silence du palier. « Superman punch » prend plus de temps
que « Jab » sans rien calculer ; une minuterie fixe aurait pu couper un mot.

**Le déroulé est une donnée.** `Drill.cues(steps)` calcule d'avance tout ce
que la voix dira (répétition, étape, palier, silence). Le contrôleur la
parcourt avec un index : la pause garde l'index, la reprise repart du coup
coupé. Le calcul se teste sans attendre.

**Une boucle qu'on peut interrompre.** Chaque passage de la voix reçoit un
numéro ; une pause ou un arrêt le rend périmé, et la boucle s'arrête à sa
prochaine vérification. Le même principe protège le lecteur audio : une
annonce coupée entre son chargement et sa lecture ne joue plus.

**Les phases de la séance en `sealed class`** : préparation, échec,
« Commencer », coup en cours (en pause ou non), note, fin.

**« Commencer » avant chaque enchaînement.** La voix ne part pas seule : on a
le temps de lire la séquence, de poser le téléphone et de se mettre en
garde.

**Une note enregistrée tout de suite.** « Arrêter » n'a donc pas besoin de
confirmation : rien n'est perdu. Les trois boutons de note ont le même
poids et affichent chacun l'échéance qu'ils donnent : la note reste un
choix honnête.

**Une séance de 5 enchaînements, réglable de 1 à 20**, les plus en retard
d'abord. « Continuer » propose les suivants, sans ceux déjà notés.
« Réviser en avance » prend les prochains quand rien n'est à réviser.

**Pause en arrière-plan, reprise à la main** : sinon la voix parlerait dans
une poche. L'écran reste allumé pendant la séance.

**Voix indisponible : la séance continue sans le son.** Si la voix échoue,
le contrôleur la remplace par `SilentSpeaker`, qui ne dit rien mais prend à
peu près le temps du mot ; un bandeau le dit. **Une pause n'est pas une
panne** : une annonce coupée pendant son chargement n'est pas une erreur.

**Le contrat `Speaker` a payé.** Passer de la synthèse aux enregistrements
n'a changé ni le contrôleur ni les tests de la séance : seulement la classe
branchée dans `main.dart`.

## 7. Les tests et la qualité

**Quatre niveaux de tests.**
- **Règles pures** (`test/models/`) : libellés, signature, Leitner,
  déroulé, recherche.
- **Base** (`test/data/`) : une vraie base SQLite en mémoire, neuve pour
  chaque test. Un faux ne vérifierait ni les `CHECK`, ni les cascades, ni
  les transactions ; certains tests écrivent exprès du SQL brut, pour voir
  la base refuser seule.
- **Contrôleurs** (`test/state/`) : sur de faux repositories.
- **Écrans** (`test/ui/`) : l'application entière sur des faux, qui
  décident de ce qu'une lecture renvoie, quand elle répond et quand elle
  échoue. Ils écrivent vraiment, en mémoire : un test suit le parcours
  complet, de la tuile touchée à la ligne dans la liste.

**Le temps des tests est factice.** Une séance de deux minutes se teste en
quelques millisecondes : `pump(durée)` avance l'horloge et déclenche les
minuteries. `pumpAndSettle` (« attendre que tout soit fini ») est interdit
pendant qu'une roue de chargement tourne : elle ne finit jamais.

**Un plugin natif testé sans téléphone.** Le lecteur audio se passe au
constructeur : le test donne un faux qui compte les lectures.

**Des écrans de vrai téléphone.** Les tests tournent sur un écran de Pixel
(412 × 915), pas sur l'écran de test par défaut (800 × 600) ; d'autres sur
un écran de 320 px avec le texte doublé, pour l'accessibilité. Ce test a
trouvé deux débordements et a fait changer la mise en page du formulaire.

**Des règles d'analyse strictes** : Dart ne devine plus un type
(`strict-casts`, `strict-inference`, `strict-raw-types`), un `Future`
oublié est signalé (`unawaited_futures`), les imports ont tous la même forme
et le même ordre.

**Du code propre** (*Clean Code*, Robert C. Martin). Des noms qui disent
tout : un verbe pour une méthode (`addStep`), `is` / `has` pour un booléen
(`isSaving`), jamais une variable d'une lettre. Des commentaires réduits de
644 à une soixantaine de lignes : il ne reste que le « pourquoi » que le
code ne peut pas dire (un comportement surprenant d'une bibliothèque, une
contrainte, un garde-fou). Les renvois à la spécification sont dans les
noms des tests, pas dans le code.

**Des performances vérifiées sans suroptimiser.** Pas de requête N+1 ; le
catalogue lu une fois ; la base hors du fil de l'écran (*isolate*) ; la
liste de l'accueil et la grille construites paresseusement (seules les
lignes visibles existent) ; les images décodées à leur taille d'affichage ;
un seul lecteur audio réutilisé. Le filtre de recherche est recalculé à
chaque affichage : sur quelques centaines d'enchaînements, c'est
imperceptible, et un cache ajouterait de l'état à synchroniser.

**Les fichiers générés ne sont pas versionnés.** La CI vérifie le formatage
**avant** de les générer (on ne juge que le code écrit à la main), puis
lance l'analyse et les tests à chaque push.

**Une revue finale** avant la publication, à la recherche de défauts réels.
Cinq ont été trouvés et corrigés, chacun avec son test quand c'était
possible (voir § 9).

## 8. La sécurité et la livraison

**Aucun accès à Internet.** L'APK final ne demande pas l'autorisation
`INTERNET` (vérifié avec `aapt dump permissions`) : Android lui interdit
tout accès au réseau. Le lecteur audio ajoute `ACCESS_NETWORK_STATE`, qui
permet seulement de savoir si le téléphone est connecté.

**La sauvegarde Android est gardée.** Android peut copier les données dans
le compte Google de l'utilisateur, si celui-ci l'a activé ; c'est Android
qui le fait, pas Cadence. En changeant de téléphone, on retrouve ses
enchaînements. « À propos » le dit plutôt que de promettre que les données
ne quittent jamais l'appareil.

**Pas d'injection, pas de chemin construit depuis une saisie.** drift écrit
des requêtes paramétrées ; les fichiers de voix et d'images viennent du
catalogue, jamais de ce que tape l'utilisateur. Les données sont validées
deux fois : par les règles, puis par la base. Un seul point d'entrée, pas de
lien profond ni de WebView.

**Les journaux coupés en version finale** : `debugPrint` y écrirait les
erreurs dans les journaux du téléphone.

**La signature.** Android n'installe une mise à jour que si elle est signée
par la même clé que la version installée. La clé et ses mots de passe
restent hors du dépôt (`key.properties`, `*.jks` dans `.gitignore`), avec
une copie de secours. **Sans clé, la version finale refuse de se
construire** : un APK signé par erreur avec la clé de débogage ne pourrait
jamais être mis à jour par la vraie.

**La publication sur tag.** Pousser un tag `v…` lance le workflow de
livraison : les contrôles de la CI (réutilisés tels quels, `workflow_call`),
la vérification que le tag correspond à `pubspec.yaml`, la clé reconstituée
depuis les secrets du dépôt, la construction, puis la release GitHub. La
release est construite par GitHub depuis le commit du tag, pas sur une
machine personnelle.

**Une chaîne de livraison protégée.** La CI n'a que le droit de lire le
dépôt ; seul le job qui publie peut écrire, et il n'exécute pas d'action
tierce (`gh release create`). Les actions sont désignées par leur empreinte
(SHA) : un tag comme `@v4` peut être déplacé après coup, une empreinte non.

**Un APK par processeur.** Un APK universel contient le code de trois
familles de processeurs (64 Mo) ; séparés, ils pèsent de 22 à 26 Mo. Pas
d'*App Bundle* : il ne sert qu'à un store, hors du périmètre.

**Pas d'obfuscation.** Le code est public : le rendre illisible dans l'APK
ne cache rien, et rendrait les traces d'erreur illisibles.

**Des captures authentiques**, prises sur le téléphone avec le jeu de
démonstration, plutôt que des maquettes.

## 9. Ce qui a changé en route

Les décisions qui ont été remises en cause, et ce qui l'a montré.

| Au départ | Finalement | Ce qui a décidé |
|---|---|---|
| `sqflite`, SQL écrit à la main | drift | L'application va évoluer : des migrations versionnées et des requêtes vérifiées à la compilation |
| Attraper l'erreur `UNIQUE` pour le doublon | Vérifier avant d'écrire | L'erreur SQLite n'a pas la même forme dans l'application et dans les tests |
| Synthèse vocale du téléphone, avec des noms écrits pour être prononcés (« Djab ») | Voix enregistrée | La voix ne plaisait pas à l'essai et changeait d'un téléphone à l'autre |
| Un fichier par mot, joués à la suite | Une phrase par annonce, d'une seule génération | Trois mots collés ne font pas une phrase ; deux générations donnaient deux voix |
| La même annonce aux trois paliers, accélérée | L'annonce raccourcit avec la vitesse | Plus naturel, et la mémoire travaille au palier rapide |
| La cible dite seulement si elle n'est pas celle par défaut | Toujours dite quand il y avait un choix | Un débutant seul doit savoir où frapper |
| La voix démarre seule | « Commencer » avant chaque enchaînement | Le temps de se mettre en garde |
| Interface Material par défaut | L'affiche de combat | Jugée « très IA » par une personne qui l'a vue |
| Formulaire en colonnes fixes | Une page qui défile, en-tête épinglé | Le test à 320 px avec texte doublé |
| Cinq images de famille, retirées, puis neuf images de techniques | Une image par famille (6), coudes compris | Toutes les techniques illustrées tout de suite ; le repli accepte une image par technique plus tard |
| « Ouvrir l'existant » remplaçait le formulaire (`pushReplacement`) | La fiche s'empile, puis le formulaire se ferme | L'accueil relisait sa liste avant l'enregistrement |

**Les défauts de la revue finale**, tous corrigés avant la V1 :

| Défaut | Correction |
|---|---|
| Une pause entre le chargement d'une annonce et sa lecture laissait passer la voix | Chaque annonce est numérotée ; une annonce arrêtée ne joue plus |
| Un réglage du mauvais type empêchait l'application de s'ouvrir | Une lecture qui échoue donne la valeur par défaut |
| Un enchaînement supprimé affichait une erreur et un « Réessayer » inutile | « Enchaînement supprimé », sans bouton |
| Un enchaînement créé partageait la liste modifiable du formulaire | Une copie non modifiable |
| La liste était lue en deux requêtes hors transaction | Une seule transaction |

**Défaut connu, gardé pour la V1** : malgré une seule génération, le timbre
de la voix change à partir de la 75ᵉ annonce. Une reprise en lots courts est
prévue.
