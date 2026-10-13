# Spec 005 : test humain et capitalisation des pièges

Statut : validée
Date : 2026-10-11, complétée le 2026-10-13 (revue IA de la PR #18 de FieldOps)

## Besoin

En tant que développeur qui confie des fonctionnalités à l'agent, je veux que chaque fonctionnalité soit testée par un humain dans l'application réelle avant d'être déclarée terminée, et que chaque piège découvert à ce test devienne une règle relue au cadrage suivant, afin que la chaîne ne refasse pas deux fois la même erreur.

Constats d'origine (2026-10-11) :

- `/implement` s'arrête quand les tests automatiques passent. Rien n'oblige à vérifier la fonctionnalité dans l'application démarrée, où apparaissent les erreurs que ni la spec ni les tests n'avaient prévues. Par exemple, sur FieldOps : une règle métier appliquée sur un seul chemin (quantité disponible recalculée à la création d'une réservation, pas à son annulation), une convention commune non réutilisée (pagination de l'API), un ordre non évident (données fictives chargées avant la migration).
- Quand un tel piège est corrigé, la leçon finit dans la rubrique « Corrections et limites » du journal de la branche. Ce journal décrit l'état d'une branche : personne ne le relit au cadrage d'une fonctionnalité voisine. L'agent redécouvre donc le même piège plus tard.

## Principes

1. **Le test humain ne se délègue pas.** L'agent n'a pas accès à l'application démarrée par l'humain : il ne peut ni simuler ni sauter ce test. Une fonctionnalité n'est terminée qu'après un retour positif explicite.
2. **Un piège coûte une fois.** Ce qui a demandé un aller-retour au test devient une règle écrite, relue au cadrage des fonctionnalités suivantes.
3. **Un store maigre et fiable vaut mieux qu'un store gonflé.** On ne capitalise que ce qui se reproduira sur une fonctionnalité analogue. En cas de doute, on n'écrit rien.
4. **Le dépôt reste la seule mémoire** (spec 004). Les pièges sont des fichiers versionnés, relus en PR, jamais une mémoire locale de l'agent.
5. **Pas de conflit par construction** (spec 004). Un fichier par piège : deux PR qui capitalisent des pièges différents ne touchent jamais le même fichier.

## Test humain dans `/implement`

Nouvelle étape, pour une nouvelle fonctionnalité comme pour une correction, après « lint et tests au vert » et avant la mise à jour des documents de référence :

1. L'agent demande à l'humain de tester la fonctionnalité dans l'application démarrée. Il propose les scénarios à jouer : le parcours nominal et chaque cas limite de la spec. Il attend le retour.
2. **Retour négatif** (bug, comportement inattendu, configuration manquante) : l'agent consigne le symptôme rapporté, cherche la cause, ajoute un test qui échoue sur ce cas, corrige jusqu'au vert, puis redemande un test. Il ne considère jamais un correctif comme suffisant sans un nouveau retour, quel que soit le nombre de boucles.
3. **Retour positif** : l'agent passe à la capitalisation, puis aux documents de référence et au récapitulatif.
4. Chaque boucle négative est consignée dans la rubrique « Corrections et limites » du journal de la branche : symptôme, cause, correctif et commit.
5. Si l'humain déclare le test impossible (pas d'environnement, fonctionnalité sans effet visible), l'agent le consigne dans le journal et dans la section « Ce que l'humain a vérifié » de la PR, puis continue.
6. Une PR sans changement de comportement observable (règle n°1 de `CLAUDE.md` : refactor, chore, docs, ci…) n'a pas de test humain : la PR l'indique « sans objet ». « Sans objet » n'est jamais admis pour une fonctionnalité ou une correction.

## Les pièges : `docs/learnings/`

- **Un fichier par piège** : `docs/learnings/<slug>.md`, où `<slug>` décrit le piège en kebab-case (exemple : `quantite-disponible-non-recalculee-a-l-annulation.md`).
- **Contenu** : un titre `# <titre actionnable>`, une ligne `Domaine :` (un terme du glossaire ou un module de l'architecture technique, sinon `transverse`), une ligne `Statut :` (`actif`, `promu` ou `obsolète`), une ligne `Date :`, puis cinq rubriques :
  - **Symptôme** : ce que l'humain a observé au test ;
  - **Cause racine** : le mécanisme, pas le symptôme ;
  - **Règle pour la prochaine fois** : à l'impératif, sur ce que le code doit faire ou éviter, et la protection durable qui la porte (test, validation, ordre de déclaration). Jamais « laisser un commentaire dans le code » : le fichier de piège est la trace ;
  - **Où** : chemins, mécanismes ou patterns concernés, pour que la règle soit vérifiable ;
  - **Vu sur** : spec et branche où le piège est apparu.
- **Cycle de vie** :
  - `actif` : relu au cadrage ;
  - `promu` : la règle est devenue générale, et elle a été déplacée dans `CLAUDE.md`, un skill ou un subagent par une PR. Le fichier reste, avec un lien vers sa nouvelle place ;
  - `obsolète` : le code concerné a disparu ou le piège ne peut plus se produire. Le fichier reste, avec la raison.
- Un fichier de piège peut être modifié après son merge (enrichissement, changement de statut). Il n'est jamais supprimé.

### Subagent `learning-curator`

- **Outils** : `Read`, `Grep`, `Glob`, `Write`, `Edit`. Pas de `Bash` : il n'exécute rien et n'écrit que dans `docs/learnings/`. L'agent principal lui fournit la date.
- **Restriction technique** : un hook `PreToolUse` de `.claude/settings.json`, de matcher `*`, lance `.claude/hooks/restrict-learnings.sh` sur chaque appel d'outil. Claude Code renseigne `agent_type` dans l'entrée d'un hook lancé pendant un subagent. Le hook :
  - laisse passer tout appel dont `agent_type` est absent, nul, ou différent de `learning-curator` et de `<plugin>:learning-curator` (session principale, autres subagents) ;
  - laisse passer `Read`, `Grep` et `Glob` ;
  - laisse passer `Write` et `Edit` seulement sur un fichier `$CLAUDE_PROJECT_DIR/docs/learnings/<slug>.md`, où `<slug>` est en kebab-case (minuscules, chiffres et tirets) : ni sous-dossier, ni autre extension, ni `..` ;
  - refuse tout autre outil (`Bash` et `MultiEdit` compris, absents des outils du subagent), un fichier de piège ou un dossier `docs/learnings/` qui est un lien symbolique, et toute entrée qu'il ne sait pas lire (JSON invalide, champ absent, `jq` ou `CLAUDE_PROJECT_DIR` absents) : fermeture en cas de panne, comme `protect-secrets.sh` (spec 002) ;
  - refuse par le code de sortie 2, avec un message sur stderr qui cite le chemin refusé.
- **Invocation** : par `/implement`, après un retour positif, et seulement si le test humain a demandé au moins une boucle négative. Aussi quand l'humain demande explicitement de retenir quelque chose (« retiens ça »). Jamais quand la fonctionnalité passe du premier coup.
- **Entrée** : la spec, le symptôme rapporté, la cause identifiée et le correctif (commit).
- **Méthode** :
  1. **Filtre** : ne capitalise pas une faute de frappe, un oubli ponctuel, une erreur d'environnement local, un cas sans équivalent futur plausible, ni une règle déjà écrite dans `CLAUDE.md` ou un skill. Dans ce dernier cas, il signale la règle existante qui n'a pas été appliquée.
  2. **Déduplication** : il cherche dans `docs/learnings/` un piège équivalent. S'il en trouve un, il l'enrichit seulement si le cas apporte un élément nouveau (symptôme, fichier), sans créer de doublon.
  3. **Rédaction** : il crée le fichier au format ci-dessus.
  4. **Compte rendu** : le fichier créé ou enrichi, ou « aucun piège durable, rien écrit » avec la raison.
- La capitalisation ne bloque jamais la fonctionnalité : si le subagent n'écrit rien, `/implement` continue.

### Relecture des pièges

- `/spec` et `/implement` lisent les pièges `actif` dont le domaine ou la rubrique « Où » recoupe la fonctionnalité, avant d'écrire la spec ou les tests. Une règle de piège qui s'applique devient un critère d'acceptation ou un test.
- Le récapitulatif de `/implement` cite les pièges appliqués.
- Le `reviewer` signale en « À corriger » un changement qui enfreint la règle d'un piège `actif`.
- Le `reviewer` vérifie aussi la ligne « Test humain » de la PR (ou, avant son ouverture, le journal) : résultat et nombre de boucles pour un changement de comportement, piège créé ou « rien écrit » motivé après une boucle négative, « sans objet » seulement sans changement de comportement. La revue IA en CI lit la description par `gh pr view <numéro> --json title,body`.

## Critères d'acceptation

### `init.sh` (ajouts à `tests/init-script.sh`)

- CA1 : Étant donné une cible vide, quand je lance `init.sh`, alors `docs/learnings/.gitkeep` existe et `.claude/agents/learning-curator.md` est copié.
- CA2 : Étant donné un template qui contient ses propres pièges dans `docs/learnings/`, quand je lance `init.sh`, alors aucun de ces fichiers n'est copié dans la cible : les pièges du template ne concernent pas le projet cible.
- CA3 : Étant donné une cible qui a déjà un `docs/learnings/` avec des fichiers, quand je lance `init.sh`, avec ou sans `--force`, alors ces fichiers ne sont pas modifiés.

### CI du template (`template-ci.yml`)

- CA4 : Étant donné `.claude/agents/learning-curator.md`, quand la CI s'exécute, alors elle vérifie que sa liste d'outils est exactement `Read, Grep, Glob, Write, Edit`, et elle échoue si `Bash` y apparaît.
- CA13 : Étant donné `.claude/settings.json`, quand la CI s'exécute, alors elle vérifie qu'un hook `PreToolUse` de matcher `*` lance `.claude/hooks/restrict-learnings.sh`, que ce script est exécutable, et que le `name:` de `learning-curator.md` est celui que le hook reconnaît.
- CA14 : Étant donné `.github/workflows/ai-review.yml`, quand la CI s'exécute, alors elle vérifie que la consigne de la revue IA lit la description de la PR par `gh pr view … --json title,body`.

### Hook `restrict-learnings.sh` (`tests/restrict-learnings.sh`, lancé par le job « Garde-fous »)

- CA15 : `Write` ou `Edit` sur `<projet>/docs/learnings/quantite-non-recalculee.md`, existant ou non : accepté (code 0), y compris si `CLAUDE_PROJECT_DIR` finit par `/`.
- CA16 : `Write`, `Edit` ou `MultiEdit` sur un fichier hors de `docs/learnings/` (`README.md`, `CLAUDE.md`, `.claude/agents/reviewer.md`, `src/app.ts`) : refusé (code 2), message qui cite le chemin.
- CA17 : chemin qui sort du dossier ou n'a pas la forme attendue : `docs/learnings/../CLAUDE.md`, sous-dossier `docs/learnings/a/b.md`, extension `.txt`, `.gitkeep`, slug avec majuscules ou espaces, `docs/learnings/` d'un autre projet (`/tmp/autre/docs/learnings/x.md`), chemin relatif, saut de ligne final ou caractère NUL dans le nom : refusé.
- CA18 : `Read`, `Grep` et `Glob` : acceptés ; `Bash`, `MultiEdit` ou tout autre outil : refusé.
- CA19 : fichier de piège existant qui est un lien symbolique, ou dossier `docs/learnings/` qui est un lien symbolique : refusé.
- CA20 : pour `learning-curator`, entrée illisible (JSON invalide, entrée vide, `tool_name` ou `file_path` absent), `jq` absent, `CLAUDE_PROJECT_DIR` absent ou vide : refusé.
- CA21 : `init.sh` copie `.claude/hooks/restrict-learnings.sh` et `tests/restrict-learnings.sh` dans la cible (ajout à `tests/init-script.sh`).
- CA25 : appel de la session principale (`agent_type` absent ou nul) ou d'un autre subagent (y compris un nom voisin comme `learning-curator-bis`) : accepté, quel que soit l'outil ou le chemin ; `<plugin>:learning-curator` est traité comme `learning-curator`. `agent_type` non textuel, JSON invalide ou `jq` absent : refusé quel que soit l'agent, faute de savoir qui appelle.

### Relecture humaine (consignes, non testables automatiquement)

- CA5 : `/implement` contient l'étape de test humain : scénarios proposés, attente du retour, boucle négative avec test qui échoue avant correction, nouvelle demande de test après chaque correctif, consignation dans le journal.
- CA6 : `/implement` invoque `learning-curator` après un retour positif précédé d'au moins une boucle négative, et ne l'invoque pas après un premier test positif.
- CA7 : `learning-curator` décrit le filtre, la déduplication, le format, le cycle de vie et le compte rendu « rien écrit ».
- CA8 : `/spec`, `/implement` et le `reviewer` relisent les pièges `actif` selon la section « Relecture des pièges ».
- CA9 : la définition du « done » de `CLAUDE.md` exige un test humain positif (ou son impossibilité consignée) et un piège capitalisé ou un « rien écrit » motivé après une boucle négative.
- CA10 : le modèle de PR demande le résultat du test humain, le nombre de boucles et les pièges créés ou enrichis.
- CA11 : le README décrit la capitalisation des pièges et l'ajoute aux fichiers à retirer après l'initialisation du template, si besoin.
- CA22 : la définition du « done » de `CLAUDE.md` et le modèle de PR admettent « sans objet » pour le test humain, seulement sans changement de comportement observable.
- CA23 : le `reviewer` vérifie la ligne « Test humain » de la PR selon la section « Relecture des pièges ».

### Test réel du hook

- CA24 : Dans une vraie session Claude Code, `learning-curator` lancé sur une demande d'écrire hors de `docs/learnings/` voit son écriture refusée par le hook, et une écriture dans `docs/learnings/<slug>.md` passe. Résultat consigné dans le journal de la branche.

### Démonstration

- CA12 : La chaîne est exercée une fois en vrai sur FieldOps : une fonctionnalité avec au moins une boucle négative produit un fichier de piège, cité dans la PR FieldOps et dans le README du template. C'est la condition du statut « livrée », pas du merge.

## Cas limites et erreurs

- Plusieurs boucles négatives sur des causes différentes : un piège par cause généralisable, pas un fichier par boucle.
- Le correctif d'une boucle négative révèle un cas que la spec n'avait pas prévu : la spec est complétée dans la même PR (règle n°1 de `CLAUDE.md`), en plus du piège éventuel.
- Deux branches capitalisent le même piège en parallèle : deux fichiers aux slugs proches. Le `reviewer` de la seconde PR signale le doublon ; la fusion se fait dans cette PR.
- L'humain demande « retiens ça » sur une préférence de travail, pas sur un piège du code : c'est une règle, elle va dans `CLAUDE.md` par une PR (spec 004), pas dans `docs/learnings/`.
- `docs/learnings/` absent (projet initialisé avant cette spec) : `learning-curator` le crée.

## Hors périmètre

- Vérification du format des fichiers de piège par la CI : le `reviewer` suffit tant que le volume reste faible. À reconsidérer après une dizaine de pièges.
- Capitalisation à partir des corrections de l'humain en revue (label `agent-corrigé`) ou des points de la revue IA : seule la boucle de test humain déclenche la capitalisation, pour garder un signal fiable.
- Recherche sémantique dans les pièges : un `grep` par domaine et par chemin suffit à ce volume.

## Décisions (validation de Yanis, 2026-10-11)

- Le test humain s'applique aux nouvelles fonctionnalités comme aux corrections : toute correction change un comportement observable.
- CA12 conditionne le statut « livrée » de la spec, pas le merge, pour ne pas bloquer le template sur FieldOps.
- Pas de piège d'exemple fictif dans le template : le premier vrai piège de FieldOps sert d'exemple, cité dans le README.
- Un fichier par piège, pour éviter les conflits entre PR (même principe que la spec 004).

## Décisions (complément du 2026-10-13)

- La revue IA de la PR #18 de FieldOps a relevé que la limite de `learning-curator` à `docs/learnings/` ne tenait qu'à son prompt (moindre privilège). Yanis demande de traiter tous les points de cette revue : la restriction technique sort du hors périmètre.
- Hook branché dans `.claude/settings.json` et filtré sur `agent_type`. La première version déclarait le hook dans l'en-tête du subagent (champ `hooks:` documenté par Claude Code) : le test réel (CA24) a montré que Claude Code 2.1.291 ne l'exécute pas, ni en subagent ni avec `--agent`, et l'écriture dans `README.md` est passée. Une trace a confirmé que le hook de `settings.json` reçoit `agent_type: "learning-curator"` pendant le subagent.
- Contrepartie assumée : le hook tourne sur chaque appel d'outil de toute session, revue IA en CI comprise (un lancement de `jq`), et il refuse tout si `jq` manque, au-delà des outils que `protect-secrets.sh` bloque déjà.
- La protection dépend du champ `agent_type` et du nom du subagent : vérifiée en vrai une fois (CA24, Claude Code 2.1.291), elle disparaîtrait sans alerte si Claude Code cessait de transmettre ce champ. La CI vérifie le nom (CA13), pas le champ.
- `MultiEdit` est refusé : il n'est pas dans les outils du subagent (moindre privilège).
- Le test humain ne vise que les changements de comportement observable, ce que la décision du 2026-10-11 sous-entendait (« toute correction change un comportement observable ») sans l'écrire.

## Questions ouvertes

- Aucune.
