# Spec 009 : design system et maquette, entre la spec et les tests

Statut : validée
Date : 2026-10-14

## Besoin

En tant que développeur qui construit un produit avec écrans, je veux que la chaîne me demande, juste après la spec, si la fonctionnalité a besoin d'un design system et d'une maquette, et qu'elle les produise et les fasse valider avant les tests, afin que le code transcrive un rendu décidé au lieu de l'inventer.

Constats d'origine (2026-10-14, projet Tidemark, construit avec la chaîne) :

- `/spec` ne prévoit aucune étape de maquette, alors que Tidemark l'exige pour chaque écran : la méthode a été écrite à la main dans son plan et son `CLAUDE.md` (friction notée dans son plan).
- La méthode de Tidemark fonctionne : charte en artefact Claude « Design System », maquette en artefact « Design » par spec, copie versionnée dans `docs/maquettes/` qui fait foi. Ses limites aussi : les captures PNG n'ont pas pu être produites depuis l'artefact privé (reportées), et les liens des artefacts ne s'ouvrent que pour leur auteur.
- Un projet sans écran (API, CLI, le template lui-même) ne doit rien subir de cette étape.

Le template n'a ni cahier des charges ni architecture technique propres (spec 003, « Hors périmètre »), et pas de piège dans `docs/learnings/` : aucun n'a été relu pour cette spec.

## Principes

1. **Une question, à chaque spec, avant les tests.** `/spec` pose la question en fin de rédaction ; la réponse est écrite dans la spec et validée avec elle. `/implement` refuse de lancer les tests tant qu'elle manque ou qu'une maquette demandée n'est pas validée.
2. **Le design system se fait une fois, la maquette à chaque spec.** La question du design system n'est posée que tant que le projet n'en a pas.
3. **Une proposition, pas un réflexe.** Pour une spec sans écran, ou un projet dont l'architecture technique dit qu'il n'a pas d'interface, l'agent propose « sans objet » avec la raison ; l'humain confirme en une réponse.
4. **Artefact pour itérer, dépôt pour faire foi** (décision de Yanis, 2026-10-14). L'artefact Claude sert à explorer et à commenter ; la copie versionnée dans `docs/maquettes/` (source HTML) est la référence du code, des tests et de la revue.
5. **Pas de capture automatique de l'artefact** (décision de Yanis, 2026-10-14). Aucun moyen éprouvé ne rend un PNG depuis un artefact. Les captures PNG sont facultatives : faites à la main par l'humain quand il les juge utiles, ou prises dans l'application lancée en développement au test humain.
6. **La maquette peut corriger la spec.** Un état révélé par la maquette (vide, chargement, erreur) qui manque aux critères d'acceptation est ajouté à la spec, qui repasse par la validation.
7. **Rien ne casse pour les projets en cours.** Une spec validée avant cette spec, sans ligne « Design », n'est pas refusée : `/implement` pose la question une fois et ajoute la ligne.

## La question et sa réponse

Le modèle `docs/templates/spec.md` gagne une ligne d'en-tête, sous « Date » :

```
Design : à décider | sans objet (<raison>) | charte et maquette | maquette
```

- **sans objet** : la fonctionnalité ne touche aucun écran, ou l'humain décide de s'en passer. La raison est obligatoire.
- **charte et maquette** : le projet n'a pas encore de design system (`docs/maquettes/000-charte/` absent) ; il est fait d'abord, puis la maquette de la spec.
- **maquette** : la charte existe ; seule la maquette de la spec est faite.

`/spec`, après son étape 8 (enregistrement de la spec ; numérotation après la spec 008), pose la question en une fois : « charte et maquette », « maquette », ou « sans objet », avec la proposition de l'agent et sa raison. Il écrit la réponse dans la ligne « Design ». S'il en résulte une charte à faire et que `docs/plan.md` existe (spec 008), il propose de l'ajouter au plan comme un écart.

## La skill `/maquette`

Fichier : `.claude/skills/maquette/SKILL.md`, sans `disable-model-invocation` : comme les autres skills de la chaîne (spec 008), l'agent la propose quand la ligne « Design » le demande, et la lance après l'accord de l'humain, sans commande à taper. Argument : le chemin de la spec. Elle ne s'exécute que si la ligne « Design » demande une charte ou une maquette.

1. **Charte**, si demandée : un artefact « Design System » au nom du projet (jetons de couleur en thème clair et sombre, typographie, espacements, rayons, composants communs avec leur aperçu). Copie dans `docs/maquettes/000-charte/` : `README.md` (statut, lien de l'artefact, inventaire des composants), `tokens.json`, et un dossier par composant.
2. **Maquette** : un artefact « Design » construit sur la charte, qui montre chaque écran de la spec dans ses états nominal, vide, chargement et erreur, en thème clair et sombre si la charte a les deux. Données fictives uniquement. Copie dans `docs/maquettes/NNN-titre-court/` (même numéro et même titre que la spec) : source HTML de chaque écran, et `README.md` (statut, lien de l'artefact, tableau des écrans et des états, avec leur capture quand l'humain en a ajouté une).
3. **Captures** (facultatives) : l'agent ne les produit pas. Si l'humain en dépose (`<ecran>-<etat>[-sombre].png`), l'agent les référence dans le `README.md`.
4. **Spec** : la section « Maquette » (nouvelle, facultative dans le modèle) renvoie vers `docs/maquettes/NNN-titre-court/` et liste les écrans. Un état absent des critères d'acceptation y est ajouté (principe 5).
5. **Validation** : l'humain commente l'artefact ou la PR ; l'agent corrige l'artefact et sa copie jusqu'à l'accord, puis passe le statut du `README.md` à « validée ».
6. **Sans artefact** (outil indisponible, compte sans accès) : la skill le dit et s'arrête ; l'humain choisit entre attendre l'accès ou produire le HTML directement dans `docs/maquettes/`. Ce repli est consigné dans le journal et la PR.

Travail sur une branche `docs/maquette-NNN-titre-court` avec son journal, et une PR. Les liens des artefacts sont privés : ils restent dans le `README.md` des maquettes, signalés comme visibles par leur seul auteur.

## Effets sur `/implement` et la revue

- **Étape 1** : en plus du statut « validée » de la spec, vérifie la ligne « Design ». « À décider » ou absente : pose la question, écrit la réponse, et attend l'accord. Maquette demandée : vérifie que le `README.md` de `docs/maquettes/NNN-…/` (et de `000-charte/` si demandée) est au statut « validée ». Sinon, s'arrête et propose `/maquette`.
- **Étape 4** : transmet à `test-writer` le chemin de la maquette, pour que les états montrés soient couverts par les tests quand les critères d'acceptation les décrivent.
- **Étape 6** : implémente à partir de la maquette et des jetons de la charte.
- **Étape 8** (test humain) : propose de comparer l'application et la maquette, écran par écran. Les captures de l'application lancée en développement, si l'humain en prend, vont dans la PR à côté du lien de la maquette.
- **`reviewer`** : signale un écran du diff sans maquette alors que la spec en demande une, et une valeur visuelle codée en dur quand la charte définit un jeton.

## Critères d'acceptation

### Modèle et skills (vérifiés par la CI du template)

- CA1 : `docs/templates/spec.md` contient, sous « Date », la ligne `Design : à décider | sans objet (<raison>) | charte et maquette | maquette`, et une section « Maquette » marquée facultative.
- CA2 : `.claude/skills/maquette/SKILL.md` existe, sans `disable-model-invocation: true`, avec un `description` non vide, et `init.sh` le copie dans un projet cible.
- CA3 : Les tests existants (`tests/*.sh`) passent sans modification de leurs vérifications actuelles.

### Question après la spec (test humain, sur un projet jetable)

- CA4 : Étant donné une fonctionnalité avec un écran, dans un projet sans `docs/maquettes/000-charte/`, quand `/spec` termine, alors l'agent pose la question en proposant « charte et maquette », et écrit la réponse dans la ligne « Design ».
- CA5 : Étant donné un projet dont la charte existe, quand `/spec` termine pour une fonctionnalité avec écran, alors la question ne propose pas de refaire la charte.
- CA6 : Étant donné une fonctionnalité sans écran, quand `/spec` termine, alors l'agent propose « sans objet » avec une raison, et l'humain peut confirmer en une réponse.

### Contrôle avant les tests (test humain)

- CA7 : Étant donné une spec validée dont la ligne « Design » demande une maquette non validée, quand l'humain lance `/implement`, alors l'agent s'arrête avant `test-writer` et propose `/maquette`.
- CA8 : Étant donné une spec validée sans ligne « Design » (antérieure à cette spec), quand l'humain lance `/implement`, alors l'agent pose la question une fois, écrit la réponse, et continue si elle est « sans objet ».
- CA9 : Étant donné une spec « sans objet », quand l'humain lance `/implement`, alors le déroulé est celui d'avant cette spec, sans étape supplémentaire.

### La skill `/maquette` (test humain)

- CA10 : Étant donné une spec « charte et maquette », quand l'humain lance `/maquette`, alors la charte est produite et copiée dans `docs/maquettes/000-charte/` avant la maquette, et la maquette n'utilise que ses jetons.
- CA11 : Étant donné une maquette produite, alors `docs/maquettes/NNN-titre-court/` contient la source HTML de chaque écran de la spec, et un `README.md` au statut « brouillon », qui liste les états nominal, vide, chargement et erreur de chaque écran, ou dit pourquoi un état est sans objet.
- CA11 bis : Étant donné une modification de l'artefact après une remarque de l'humain, alors la source HTML concernée est mise à jour dans le même commit.
- CA12 : Étant donné un état montré par la maquette et absent des critères d'acceptation, quand `/maquette` termine, alors la spec contient un critère pour cet état et repasse au statut « brouillon ».
- CA13 : Étant donné l'outil d'artefact indisponible, quand `/maquette` s'exécute, alors l'agent le dit et s'arrête ; si l'humain choisit le repli en HTML direct, la PR et le journal l'indiquent.
- CA14 : Étant donné une spec dont la ligne « Design » demande une maquette, quand la spec est validée, alors l'agent propose lui-même la maquette et la lance après accord, sans que l'humain ait tapé `/maquette`.

## Cas limites et erreurs

- Spec qui touche un écran existant sans le changer visuellement : « sans objet » proposé, avec cette raison.
- Charte modifiée après coup : les maquettes déjà validées ne sont pas reprises ; une PR de charte liste les écrans touchés.
- Projet qui a déjà une charte ailleurs (Figma, design system d'entreprise) : « maquette » seule, et le `README.md` de `000-charte/` renvoie vers la source externe au lieu de la recopier.
- Données personnelles réelles dans une maquette (noms, coordonnées d'utilisateurs finaux) : interdites, la maquette utilise des données fictives. Les noms du client et du produit sont admis : un projet client est gardé en local ou dans un dépôt privé (décision de Yanis du 2026-10-14, spec 008).
- Maquette refusée plusieurs fois : chaque boucle est consignée dans « Corrections et limites » du journal, comme au test humain.

## Hors périmètre

- Captures PNG rendues automatiquement depuis l'artefact ou depuis le HTML (navigateur piloté, Playwright) : aucun moyen éprouvé, et décision de Yanis de s'en passer.
- Tests golden ou vérification en CI des couleurs codées en dur : propres à chaque stack (Tidemark les a en Flutter). Le template les recommande dans la skill, sans les imposer.
- Transcription automatique des jetons en code : propre à chaque stack.
- Figma ou tout autre outil de design : seuls l'artefact Claude et le HTML versionné sont pris en charge.

## Questions ouvertes

- Aucune. Tranché par Yanis le 2026-10-14 : question « Design » posée par `/spec` ; le `reviewer` relève dès cette spec les valeurs visuelles codées en dur quand la charte définit un jeton ; captures PNG facultatives, faites par l'humain ou prises dans l'application en développement, jamais rendues automatiquement depuis l'artefact.
