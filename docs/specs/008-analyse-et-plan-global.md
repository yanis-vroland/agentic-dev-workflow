# Spec 008 : analyse du besoin et plan global

Statut : brouillon
Date : 2026-10-14

## Besoin

En tant que développeur qui démarre un projet avec la chaîne, je veux une première étape qui analyse le besoin fonctionnel et technique, puis un plan global des étapes tenu à jour par chaque PR, afin de savoir à tout moment où en est le projet et quoi faire ensuite, sans dépendre de la mémoire d'une session.

Constats d'origine (2026-10-14, projet Tidemark, construit avec la chaîne) :

- La chaîne commence à `/spec`. Rien ne remplit le cahier des charges ni l'architecture technique : `/spec` se contente de signaler leur absence. Sur Tidemark, l'analyse et le plan ont été faits à la main, en trois PR.
- Le seul plan du template est un `plan.md` local, exclu du dépôt. Cela contredit la spec 004 (le dépôt est la seule mémoire) : Tidemark a dû versionner le sien dans `docs/plan.md`, avec son propre format (friction notée dans son plan).
- Rien ne dit quelle fonctionnalité vient ensuite, ni dans quel ordre : le tableau « Fonctionnalités » du cahier des charges donne des statuts, pas un ordre ni des dépendances.

Le template n'a ni cahier des charges ni architecture technique propres (spec 003, « Hors périmètre »), et pas de piège dans `docs/learnings/` : aucun n'a été relu pour cette spec.

## Principes

1. **Analyser avant de spécifier.** Une nouvelle skill `/analyse` établit le besoin fonctionnel (cahier des charges) et technique (architecture technique), puis le plan. Elle n'écrit ni spec ni code.
2. **Une liste, puis une spec par lot.** L'analyse liste toutes les fonctionnalités au statut « à spécifier ». Chaque spec est rédigée par `/spec` juste avant son lot, pour tenir compte de ce que les lots précédents ont appris (pièges, décisions). Décision de Yanis, 2026-10-14.
3. **Une information à un seul endroit** (spec 003). Le plan porte l'ordre des lots, leurs dépendances, les tâches qui ne sont pas des fonctionnalités (socle, spike, charte, publication), les tâches de l'humain et les jalons. Le statut d'une fonctionnalité reste dans le cahier des charges, vers lequel le plan renvoie.
4. **Le plan est tenu à jour par la PR qui avance.** Une PR coche, dans le même commit que son travail, les cases des tâches qu'elle termine, et seulement celles-là. Aucune autre mise à jour automatique.
5. **L'humain décide des écarts.** L'agent coche ; ajouter, retirer ou réordonner un lot est une proposition, consignée dans le plan et validée par l'humain dans la PR (ADR-002).
6. **Rien ne casse pour les projets en cours.** Un projet sans `docs/plan.md`, ou avec un plan à son propre format (Tidemark), garde une chaîne qui fonctionne : `/spec` et `/implement` signalent l'absence de plan sans bloquer, et rien n'écrase un plan existant.

## La skill `/analyse`

Fichier : `.claude/skills/analyse/SKILL.md`, `disable-model-invocation: true` comme `/spec` et `/implement`. Argument : le projet décrit en quelques phrases.

1. Lit `docs/cahier-des-charges-fonctionnel.md`, `docs/architecture-technique.md`, `docs/plan.md` et les ADR. S'ils sont déjà remplis, elle passe en **mise à jour** : elle propose des modifications, elle ne réécrit pas.
2. Projet existant (du code est présent) : elle lit le code pour constater la stack, les modules, le modèle de données et les commandes. Ce qui est constaté est écrit comme constaté ; rien n'est déduit au-delà.
3. Pose les questions nécessaires (10 au maximum), regroupées par thème : objectif et périmètre, acteurs et droits, règles métier, contraintes techniques (plateformes, hébergement, données sensibles), échéances. Elle n'invente aucune règle métier : ce qui n'est pas tranché va dans « Questions ouvertes » du cahier des charges.
4. Remplit le cahier des charges : objectif et périmètre, acteurs et droits, glossaire, règles métier tranchées, parcours, et le tableau « Fonctionnalités », chacune au statut « à spécifier ».
5. Remplit l'architecture technique : vue d'ensemble, stack, contraintes. Chaque choix structurant non tranché (moteur, base, hébergement…) devient une tâche « ADR à rédiger » du plan, jamais une décision prise par l'agent (règle n°4 de `CLAUDE.md`).
6. Crée `docs/plan.md` à partir du modèle `docs/templates/plan.md` (section suivante) : lots ordonnés, dépendances, tâches de l'humain.
7. Travaille sur une branche `docs/analyse` avec son journal, et ouvre une PR. Termine en demandant à l'humain de valider le cahier des charges, l'architecture et le plan. La prochaine étape annoncée est la spec du premier lot de fonctionnalité.

Relancer `/analyse` plus tard (nouveau périmètre, pivot) suit le mode mise à jour de l'étape 1.

## Le plan global

Modèle : `docs/templates/plan.md`. Fichier du projet : `docs/plan.md`, versionné. Sections :

| Section | Contenu |
| --- | --- |
| Objectif | Une phrase, renvoi vers « Objectif et périmètre » du cahier des charges, sans le recopier. |
| Règles de mise à jour | Les principes 4 et 5 de cette spec, en trois lignes. |
| Lots | Tableau ordonné : lot, contenu, dépend de, branche prévue. Un lot de fonctionnalité renvoie vers sa ligne du cahier des charges. |
| Tâches | Par lot, une case par tâche (`- [ ]`). Un lot de fonctionnalité a une seule case, cochée quand la fonctionnalité passe « livrée ». |
| Tâches de l'humain | Cases marquées **[Humain]** : validations, tests sur appareil, accès, publication. L'agent vérifie, il ne coche que ce que l'humain a confirmé. |
| Jalons | Facultatif : dates et points de décision, si l'humain en a donné. |
| Écarts au plan | Une ligne par ajout, retrait ou réordonnancement de lot : date, écart, raison, qui a décidé. |

Mises à jour, dans la PR qui fait le travail :

- `/implement`, étape 10 (documents de référence) : coche la case du lot quand la fonctionnalité passe « livrée » dans le cahier des charges.
- PR sans spec (socle, spike, ADR, publication) : coche les cases de ses tâches, règle écrite dans `CLAUDE.md`.
- `/spec` : vérifie que la fonctionnalité figure au plan. Sinon, elle le signale et propose un écart au plan, sans bloquer la rédaction.
- Conflit entre deux PR qui cochent des lignes différentes : la règle n°6 de `CLAUDE.md` s'applique (rebase par l'agent après le premier merge).

## Autres changements

- **`CLAUDE.md`** : `docs/plan.md` ajouté aux « Documents de référence », avec la règle de mise à jour ; une case du plan à jour ajoutée à la « Définition du done ».
- **`init.sh`** (spec 001) : crée `docs/plan.md` à partir du modèle s'il n'existe pas, sans jamais l'écraser, même avec `--force`, comme les deux documents de référence. Il ajoute aux étapes manuelles : « Lancer /analyse ».
- **Hook `session-start.sh`** (spec 004) : affiche le premier lot non coché du plan, après la dernière entrée de journal. Plan absent ou sans case : une ligne le dit, sans erreur.
- **README** : `/analyse` en tête du schéma du flux et du tableau des étapes ; étape 4 de l'installation « Nouveau projet » complétée par la copie du modèle de plan.

## Critères d'acceptation

### Script `init.sh` (dans `tests/init-script.sh`)

- CA1 : Étant donné un projet sans `docs/plan.md`, quand `init.sh` s'exécute, alors `docs/plan.md` est créé, identique à `docs/templates/plan.md`, et la sortie le liste parmi les fichiers créés.
- CA2 : Étant donné un projet avec un `docs/plan.md` existant, quand `init.sh` s'exécute avec ou sans `--force`, alors le fichier est inchangé, octet pour octet.
- CA3 : Étant donné un projet quelconque, quand `init.sh` s'exécute, alors les étapes manuelles affichées contiennent « /analyse », et `.claude/skills/analyse/SKILL.md` est copié.

### Hook `session-start.sh` (dans `tests/session-start.sh`)

- CA4 : Étant donné un `docs/plan.md` dont des cases sont cochées et d'autres non, quand le hook s'exécute, alors sa sortie contient la première ligne `- [ ]` du plan, et aucune ligne cochée.
- CA5 : Étant donné un projet sans `docs/plan.md`, ou un plan dont toutes les cases sont cochées, quand le hook s'exécute, alors sa sortie le dit en une ligne, et il sort avec le code 0.
- CA6 : Étant donné un plan au format libre, sans aucune case (`- [ ]` ou `- [x]`), quand le hook s'exécute, alors il sort avec le code 0, sans message d'erreur.

### Modèle et documents

- CA7 : `docs/templates/plan.md` existe et contient les sections du tableau « Le plan global », dans cet ordre. La CI du template le vérifie.
- CA8 : Les tests existants (`tests/*.sh`) passent sans modification de leurs vérifications actuelles : seules des vérifications sont ajoutées.

### Skills (test humain, sur un projet jetable créé avec `init.sh`)

- CA9 : Étant donné un projet vide et une description en trois phrases, quand l'humain lance `/analyse`, alors l'agent pose au plus 10 questions avant d'écrire, puis remplit le cahier des charges (fonctionnalités « à spécifier »), l'architecture technique et `docs/plan.md`, sur une branche `docs/analyse` avec son journal, et n'écrit ni spec ni code.
- CA10 : Étant donné une règle métier non tranchée par les réponses, quand `/analyse` écrit le cahier des charges, alors la règle figure dans « Questions ouvertes », et pas dans « Règles métier ».
- CA11 : Étant donné un cahier des charges déjà rempli, quand l'humain relance `/analyse`, alors l'agent propose des modifications et ne remplace aucune section sans accord.
- CA12 : Étant donné un choix structurant non tranché (par exemple la base de données), quand `/analyse` écrit le plan, alors il contient une tâche « ADR à rédiger », et l'architecture technique ne présente pas ce choix comme fait.
- CA13 : Étant donné une fonctionnalité absente du plan, quand l'humain lance `/spec` pour elle, alors l'agent le signale et propose un écart au plan, puis rédige la spec.
- CA14 : Étant donné un projet sans `docs/plan.md`, quand l'humain lance `/spec` puis `/implement`, alors les deux skills fonctionnent comme avant cette spec, et signalent seulement l'absence de plan.
- CA15 : Étant donné une fonctionnalité qui passe « livrée » par `/implement`, quand la PR est ouverte, alors la case de son lot est cochée dans `docs/plan.md`, dans la même PR, et aucune autre case n'a changé.

## Cas limites et erreurs

- Plan existant à un autre format (Tidemark) : jamais écrasé ni reformaté ; `/analyse` en mode mise à jour propose une migration vers le modèle, que l'humain accepte ou refuse.
- Projet sans interface : aucune tâche de charte ni de maquette n'est ajoutée au plan (la question du design relève de la spec 009).
- L'humain ne répond pas à une question de `/analyse` : elle va dans « Questions ouvertes », l'analyse continue.
- Deux PR ouvertes cochent des lignes différentes du plan : pas de conflit Git attendu (lignes distinctes) ; en cas de conflit, règle n°6.
- Description trop vague pour lister des fonctionnalités : l'agent le dit, et pose ses questions avant d'écrire quoi que ce soit.

## Hors périmètre

- Rédiger toutes les specs d'emblée (principe 2).
- Vérifier en CI la cohérence entre le plan et le cahier des charges (case cochée et statut « livrée ») : la revue IA et l'humain en sont chargés. À réévaluer si l'écart est constaté sur un projet.
- Estimation de charge ou calendrier calculé : les jalons sont ceux que l'humain donne.
- Plan du template lui-même : comme pour la spec 003, le template ne s'applique pas ses documents de référence. Son `plan.md` local reste un fichier de travail personnel.
- Étape design system et maquette après la spec : spec 009.

## Questions ouvertes

- Nom de la skill : `/analyse` (proposé) ou `/cadrage` ? (Yanis)
- Plafond de 10 questions pour `/analyse` : suffisant pour un projet réel, ou faut-il permettre un second tour ? (Yanis)
- CA4 à CA6 (plan affiché par `session-start.sh`) : à garder, ou la lecture du plan en début de session suffit-elle, consignée dans `CLAUDE.md` ? Le hook rend l'étape suivante visible sans effort, au prix d'un test de plus. (Yanis)
