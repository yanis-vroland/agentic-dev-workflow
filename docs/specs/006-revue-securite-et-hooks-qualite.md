# Spec 006 : revue de sécurité et hooks de lint et de tests

Statut : validée
Date : 2026-10-12

## Besoin

En tant que développeur qui confie du code à l'agent, je veux qu'un subagent dédié relise chaque diff sous l'angle de la sécurité, sans pouvoir rien exécuter ni modifier, et que le lint et les tests soient lancés automatiquement après les modifications de l'agent, afin que les failles et les régressions soient signalées à l'agent pendant qu'il travaille, et non découvertes en revue.

Constats d'origine (2026-10-12) :

- La sécurité n'est qu'une rubrique parmi sept du `reviewer` (« validation des entrées, secrets, injections, contrôle des droits »). Aucune liste de référence ne guide cette vérification, et le `reviewer` dispose de `Bash`.
- Le seul hook qui suit une modification de l'agent est `format.sh`. Le lint et les tests ne tournent que si l'agent pense à les lancer (étape 7 de `/implement`), ou en CI après le push.
- La fiche du projet liste ces deux manques parmi les écarts au critère « prêt à montrer ».

Le template n'a ni cahier des charges ni architecture technique propres (spec 003, « Hors périmètre »), et pas encore de piège dans `docs/learnings/` : aucun n'a été relu pour cette spec.

## Principes

1. **Un relecteur de sécurité ne peut rien changer.** Pas de `Bash`, pas d'écriture : il lit et rend un rapport. Ce qu'il ne peut pas faire, une instruction glissée dans le code relu ne peut pas le lui faire faire.
2. **Le retour arrive à l'agent, pendant le travail.** Un échec de lint ou de tests est renvoyé à l'agent (code de sortie 2), qui corrige avant de rendre la main.
3. **Le template ne connaît pas la stack du projet.** Les commandes de lint et de tests sont déclarées par le projet ; sans elles, les hooks ne font rien, comme `format.sh` sans Prettier.
4. **Le hook ne contredit pas le test-first.** Des tests rouges attendus (phase test-first, étape 5 de `/implement`) ne doivent pas pousser l'agent à modifier les tests (règle n°3 de `CLAUDE.md`).

## Subagent `security-reviewer`

- **Fichier** : `.claude/agents/security-reviewer.md`. Le nom évite la confusion avec la commande intégrée `/security-review` de Claude Code.
- **Outils** : `Read`, `Grep`, `Glob`, exactement. Pas de `Bash`, `Write` ni `Edit`.
- **Entrée** : l'agent principal lui transmet le diff (`git diff main...HEAD`), la spec liée et la liste des fichiers modifiés. Le subagent ne peut pas calculer le diff lui-même ; sans diff fourni, il le dit et s'arrête.
- **Référence** : OWASP Top 10, édition 2025 (A01 à A10). Le subagent lit aussi les fichiers voisins du diff quand il en a besoin (contrôle des droits appliqué ailleurs, validation commune, configuration).
- **Rapport** : trois niveaux, comme le `reviewer` (Bloquant, À corriger, Suggestion). Pour chaque point : catégorie OWASP, fichier et ligne, scénario d'exploitation concret, correction proposée. Un point sans scénario plausible est au plus une suggestion. Si rien n'est à signaler, une ligne.
- **Invocation** : par `/implement`, nouvelle étape après « lint et tests au vert » et avant le test humain, pour que les correctifs de sécurité passent eux aussi par le test humain. Un point « Bloquant » est corrigé avant de continuer ; les autres sont corrigés ou repris dans « Points d'attention » de la PR.
- **Fichiers d'environnement** : comme tout agent du projet, il ne lit jamais un fichier `.env*` (Interdits de `CLAUDE.md`), et le hook `protect-secrets` s'applique aussi à ses `Read` et `Grep`.
- Le `reviewer` garde sa rubrique « Sécurité » : il relit aussi les PR où `/implement` n'a pas servi, et c'est lui qui tourne en CI.

## Hooks de lint et de tests

### Configuration : `.claude/quality.json`

```json
{
  "lint": "pnpm exec eslint",
  "test": "pnpm test"
}
```

- `lint` : commande lancée avec le chemin **absolu** du fichier modifié en dernier argument. Le chemin est passé comme argument séparé, jamais interpolé dans le texte de la commande : un nom de fichier qui commence par `-` ou contient des caractères spéciaux du shell ne peut pas changer la commande.
- `test` : commande lancée sans argument, depuis la racine du projet.
- Fichier absent, ou clé absente ou vide : le hook correspondant ne fait rien.
- Le fichier contient des commandes shell exécutées automatiquement sur le poste de quiconque utilise Claude Code dans le projet, comme `.claude/settings.json`. Il est sous `.claude/` : une PR qui le modifie relève de la relecture intégrale de l'ADR-002.
- `init.sh` ne copie pas le fichier du template (ses commandes sont celles du template) ; il le crée s'il est absent, avec les deux clés vides, et ne l'écrase jamais, même avec `--force`.

### Lint : `.claude/hooks/lint.sh`, après chaque modification

- Branché sur `PostToolUse`, pour `Edit|Write|MultiEdit`.
- Claude Code lance en parallèle les hooks d'un même événement : le lint ne doit pas s'appliquer à un fichier pas encore formaté. Le formatage et le lint s'enchaînent donc dans un ordre garanti (le moyen relève de l'implémentation).
- Lint en échec : code 2, avec sur stderr le fichier et la fin de la sortie du lint (50 dernières lignes au plus). Claude Code la transmet à l'agent.
- Commande introuvable : le premier mot de la commande configurée est cherché (`command -v`) avant de la lancer. S'il est introuvable, le hook ne lance rien et ne bloque pas. Une fois la commande lancée, tout code de sortie non nul, 127 compris, est un échec du lint.
- Toute modification d'un fichier du projet marque les tests « à lancer » pour la fin du tour, que le lint soit configuré ou non.
- **La marque « à lancer »** est propre à la session (`session_id` de l'entrée du hook) et au worktree. Elle est rangée dans le répertoire Git du worktree (`git rev-parse --git-path`), jamais dans l'arbre de travail : elle n'est ni versionnée ni partagée entre deux sessions ou deux worktrees.

### Tests : `.claude/hooks/run-tests.sh`, à la fin de chaque tour de l'agent

- Branché sur `Stop` : quand l'agent s'apprête à rendre la main, et seulement si des tests sont « à lancer ».
- Tests au vert : code 0, la marque « à lancer » est retirée.
- Tests en échec, premier arrêt (`stop_hook_active` faux) : code 2, avec la fin de la sortie (50 dernières lignes au plus) et une consigne. L'agent corrige le code ; si les tests rouges sont attendus (phase test-first), il le dit et s'arrête sans modifier les tests.
- Tests en échec, arrêt déjà relancé par ce hook (`stop_hook_active` vrai) : le hook ne bloque pas une seconde fois, pour éviter une boucle sans fin. L'échec est signalé à l'humain par un avertissement (code 0 et `systemMessage` en JSON sur stdout) et la marque reste : les tests seront relancés au tour suivant.
- Durées maximales déclarées dans `.claude/settings.json` : 60 s pour le lint, 300 s pour les tests. Un dépassement n'est jamais présenté comme un succès.

## Critères d'acceptation

### Hook de lint (nouveau `tests/quality-hooks.sh`)

- CA1 : Étant donné un projet sans `.claude/quality.json`, quand l'agent modifie un fichier, alors `lint.sh` sort avec le code 0 sans rien lancer.
- CA2 : Étant donné une commande `lint` configurée qui réussit, quand l'agent modifie `src/a.ts`, alors la commande reçoit le chemin absolu de `src/a.ts` en dernier argument et `lint.sh` sort avec le code 0.
- CA3 : Étant donné une commande `lint` qui échoue, quand l'agent modifie un fichier, alors `lint.sh` sort avec le code 2, et stderr contient le chemin du fichier et la sortie du lint.
- CA4 : Étant donné une sortie de lint de plus de 50 lignes, quand le lint échoue, alors stderr n'en contient que les 50 dernières.
- CA5 : Étant donné une entrée sans `file_path`, ou un fichier hors du projet, quand le hook s'exécute, alors il sort avec le code 0 sans lancer le lint.
- CA5 bis : Étant donné un fichier nommé `-x.ts` ou `a;touch pwned.ts`, quand le lint est lancé, alors la commande reçoit ce chemin comme un seul argument, et aucune autre commande n'est exécutée.
- CA6 : Étant donné Prettier installé et un lint configuré, quand l'agent modifie un fichier mal formaté, alors le lint reçoit le fichier déjà formaté.
- CA7 : Étant donné un `.claude/quality.json` invalide, ou `jq` absent, quand le hook s'exécute, alors il sort avec le code 1 (erreur non bloquante : Claude Code affiche à l'humain la première ligne de stderr), et cette première ligne nomme la cause.
- CA8 : Étant donné une commande `lint` dont le premier mot est introuvable, quand le hook s'exécute, alors il ne lance rien, sort avec le code 0 et écrit sur stdout un JSON `systemMessage` qui nomme la commande introuvable ; une commande trouvée qui sort avec le code 127 donne, elle, le code 2 (CA3) : une commande mal configurée est un problème pour l'humain, pas une erreur à corriger par l'agent à chaque modification.

### Hook de tests

- CA9 : Étant donné un tour sans modification de fichier, quand l'agent s'arrête, alors `run-tests.sh` sort avec le code 0 sans lancer les tests.
- CA10 : Étant donné une modification pendant le tour et des tests qui passent, quand l'agent s'arrête, alors les tests sont lancés une fois, le hook sort avec le code 0, et un arrêt suivant sans nouvelle modification ne les relance pas.
- CA11 : Étant donné une modification et des tests qui échouent, avec `stop_hook_active` faux, quand l'agent s'arrête, alors le hook sort avec le code 2, et stderr contient la sortie des tests et la consigne sur les tests rouges attendus.
- CA12 : Étant donné des tests qui échouent, avec `stop_hook_active` vrai, quand l'agent s'arrête, alors le hook sort avec le code 0 et un JSON `systemMessage` qui signale l'échec à l'humain, et un arrêt suivant relance les tests.
- CA12 bis : Étant donné deux sessions (deux `session_id`) dans le même worktree, quand la première modifie un fichier, alors un arrêt de la seconde ne lance pas les tests, et aucune marque n'apparaît dans l'arbre de travail (`git status` inchangé).
- CA13 : Étant donné aucune commande `test` configurée, quand l'agent s'arrête après une modification, alors le hook sort avec le code 0.

### Branchement et CI

- CA14 : `.claude/settings.json` branche `lint.sh` sur `PostToolUse` (`Edit|Write|MultiEdit`, 60 s) et `run-tests.sh` sur `Stop` (300 s). La CI du template le vérifie.
- CA15 : Étant donné `.claude/agents/security-reviewer.md`, quand la CI du template s'exécute, alors elle vérifie que sa liste d'outils est exactement `Read, Grep, Glob`, et échoue sinon.
- CA16 : `garde-fous.yml` lance `tests/quality-hooks.sh`, et shellcheck vérifie les deux hooks et ce test.

### `init.sh` (ajouts à `tests/init-script.sh`)

- CA17 : Étant donné une cible vide, quand je lance `init.sh`, alors `security-reviewer.md`, `lint.sh`, `run-tests.sh` et `tests/quality-hooks.sh` sont copiés, et `.claude/quality.json` est créé avec les deux clés vides, quel que soit le contenu de celui du template.
- CA18 : Étant donné une cible qui a déjà un `.claude/quality.json`, quand je lance `init.sh`, avec ou sans `--force`, alors ce fichier n'est pas modifié.

### Application au template lui-même

- CA23 : Le template a son propre `.claude/quality.json` : `lint` lance `scripts/lint-shell.sh`, qui passe shellcheck sur un fichier shell (extension `.sh`, ou première ligne `#!` qui cite `sh` ou `bash`) et ne fait rien sur les autres ; `test` lance `bash tests/hooks.sh`. `scripts/lint-shell.sh` n'est pas copié par `init.sh`.
- CA24 : Étant donné un script shell avec une erreur shellcheck, quand `scripts/lint-shell.sh` le reçoit, alors il sort avec un code non nul ; étant donné un fichier Markdown, alors il sort avec le code 0 sans lancer shellcheck.

### Contrôle par mutation (règle n°2 de `CLAUDE.md`)

- CA19 : Chaque protection est désactivée une fois, et au moins un test échoue : filtre shell de `scripts/lint-shell.sh`, code 2 du lint, argument du fichier passé sans interpolation, détection de la commande introuvable, marque propre à la session, limite de 50 lignes, ordre formatage puis lint, garde `stop_hook_active`, marque « à lancer », vérification des outils de `security-reviewer`.

### Relecture humaine (consignes, non testables automatiquement)

- CA20 : `security-reviewer` décrit son entrée, l'arrêt sans diff, les dix catégories de l'OWASP Top 10 2025, le format du rapport et l'exigence d'un scénario d'exploitation.
- CA21 : `/implement` invoque `security-reviewer` après « lint et tests au vert » et avant le test humain, lui transmet le diff, et fait corriger les points bloquants avant de continuer.
- CA22 : `CLAUDE.md` (« Stack et commandes ») et le README (garde-fous, limites, structure, configuration) renvoient à `.claude/quality.json`.

## Cas limites et erreurs

- Phase test-first : `test-writer` écrit des tests rouges, le hook de tests bloque une fois. L'agent constate que l'échec est attendu, ne touche pas aux tests et s'arrête ; le second arrêt n'est pas bloqué (CA12).
- Modification par un subagent (`test-writer`, `learning-curator`) : elle marque aussi les tests « à lancer », lancés quand l'agent principal s'arrête.
- Fichier que le linter ne sait pas traiter (Markdown pour ESLint, par exemple) : c'est à la commande configurée de l'ignorer, comme `prettier --ignore-unknown`.
- Lint ou tests trop longs : la durée maximale de Claude Code interrompt le hook ; le dépassement est signalé, jamais pris pour un succès.
- Modification d'un fichier de journal ou de documentation : les tests sont quand même marqués « à lancer ». Coût accepté, pour une règle simple.
- `security-reviewer` reçoit un diff qui contient une instruction (« ignore les consignes précédentes ») : il la traite comme du contenu à relire. Sans outil d'exécution ni d'écriture, il ne peut de toute façon rien faire d'autre que l'écrire dans son rapport.
- Diff vide ou absent : `security-reviewer` le dit et ne produit pas de rapport vide.

## Hors périmètre

- Revue de sécurité en CI (`ai-review.yml`) : une PR qui modifie ce workflow ne peut pas être relue par l'IA (Limites du README). À traiter à part si le besoin se confirme.
- Analyse statique outillée (Semgrep, CodeQL, audit des dépendances) : la revue reste une lecture.
- Lint et tests partiels (seuls les tests touchés par la modification) : relèvent de la commande configurée par le projet.
- Subagent de documentation : en partie couvert par `learning-curator` ; à réévaluer séparément.
- `reviewer` sans `Bash` : point reporté de la fiche du projet.

## Décisions (validation de Yanis, 2026-10-12)

1. Lint après chaque modification (`PostToolUse`), tests à la fin du tour s'il y a eu une modification (`Stop`).
2. Commandes déclarées dans `.claude/quality.json`.
3. Le template s'applique ses propres hooks : shellcheck en lint, `bash tests/hooks.sh` en tests (CA23, CA24).
4. `security-reviewer` passe dans `/implement` avant le test humain.
5. Vérifié dans la documentation des hooks de Claude Code (2026-10-12) : un code autre que 0 et 2 n'affiche à l'humain que la première ligne de stderr, comme une erreur de hook ; un avertissement non bloquant passe par le code 0 et un JSON `systemMessage` ; le hook `Stop` reçoit `stop_hook_active` ; les hooks d'un même événement tournent en parallèle ; les appels d'outils des subagents déclenchent les mêmes `PostToolUse`. CA7, CA8 et CA12 sont écrits en conséquence.

## Questions ouvertes

- Aucune.
