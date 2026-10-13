# Journal : fix/spec-005-revue-fieldops-18

## 2026-10-13 16:14

### Fait

- Spec 005 complétée à partir de la revue IA de la PR #18 de FieldOps : hook `restrict-learnings.sh` déclaré dans l'en-tête de `learning-curator`, test humain « sans objet » sans changement de comportement, ligne « Test humain » vérifiée par le `reviewer`, description de la PR lue par la revue IA (`gh pr view --json`). CA13 à CA24.
- Tests en échec : `tests/restrict-learnings.sh` (CA15 à CA20, échec : hook absent, code 127), `tests/init-script.sh` (CA21), vérifications de `template-ci.yml` (CA13, CA14). Test du hook branché dans `garde-fous.yml`.

### Décisions

- Yanis : traiter les six points de la revue IA de la PR #18 de FieldOps, dont la restriction technique que la spec 005 laissait hors périmètre.
- Agent : hook dans l'en-tête du subagent plutôt que dans `settings.json` (actif seulement pendant `learning-curator`, sans dépendre du champ `agent_type`) ; slug limité au kebab-case, ce qui exclut `..` et les sous-dossiers par construction.

### Corrections et limites

- Les tests sont écrits par l'agent principal, pas par `test-writer` : la session est lancée depuis FieldOps et ne charge pas les subagents du template.

### Prochaine étape

- Implémenter `restrict-learnings.sh`, le déclarer dans `learning-curator.md`, l'ajouter à `init.sh`, puis test réel du hook (CA24) et ouverture de la PR.

## 2026-10-13 16:37

### Fait

- `restrict-learnings.sh` implémenté, branché dans `.claude/settings.json` (matcher `*`), filtré sur `agent_type`, copié par `init.sh`. CA13 en CI vérifie le branchement dans `settings.json`.
- Test humain « sans objet » admis sans changement de comportement (`CLAUDE.md`, modèle de PR), ligne « Test humain » vérifiée par le `reviewer`, description de la PR lue par la revue IA avec `gh pr view --json title,body`. README mis à jour (hooks, limites).
- Contrôle par mutation : 16 protections désactivées une à une, 15 font échouer au moins un test. Survivant : `file_path` absent, mutant équivalent (le chemin devient `null`, refusé par le contrôle de préfixe).
- Test réel (CA24), dans une copie jetable du template et une vraie session Claude Code 2.1.291 : `learning-curator` refusé sur `README.md` (message du hook reçu), accepté sur `docs/learnings/test-hook-ca24.md` ; la session principale écrit librement. Vérifié par `git status` de la copie.
- Toute la suite au vert : tests des hooks, du pre-commit, de la revue IA, du début de session, du journal, des hooks de qualité, des modèles, de `restrict-learnings`, du lint, d'`init.sh`, shellcheck.

### Décisions

- Agent, après le test réel : hook dans `settings.json` filtré sur `agent_type`, au lieu de l'en-tête du subagent. Contrepartie : le hook tourne à chaque appel d'outil, et refuse tout sans `jq`.

### Corrections et limites

- **Boucle négative au test réel** : le hook déclaré dans l'en-tête de `learning-curator` (champ `hooks:`, documenté) n'est jamais exécuté par Claude Code 2.1.291, ni en subagent ni avec `--agent` : l'écriture dans `README.md` est passée, et une trace a montré que la commande du hook n'était pas lancée. Les tests unitaires du script étaient verts : ils ne testaient pas le branchement. Une trace d'un hook de `settings.json` a montré le champ `agent_type: "learning-curator"`.
- **Tests modifiés après leur commit** (signalé) : `tests/restrict-learnings.sh` ajoute `agent_type` aux entrées et les cas CA25, et CA13 vérifie `settings.json` au lieu de l'en-tête. Raison : changement de mécanisme imposé par le test réel, pas un test à faire passer ; quatre cas ajoutés aussi après mutation (chemin relatif sans `/`, sans extension, `docs/` en lien symbolique, `cat` absent).
- La consigne `gh pr view --json` ne se vérifie qu'en CI : la revue IA de cette PR doit citer sa description.
- Ce piège (hook d'en-tête de subagent non exécuté) se généralise, mais le template n'a pas de `docs/learnings/` propre (CA2) : il est consigné dans la spec et le README.

### Prochaine étape

- Ouvrir la PR, puis la reprise dans FieldOps (specs 006 et 007, et ces corrections).

## 2026-10-13 16:45

### Fait

- Relecture par le subagent `reviewer` avant la PR : rien de bloquant, cinq points « À corriger », dix suggestions. Corrigés :
  - chemin terminé par un saut de ligne ou contenant un NUL accepté (la substitution `$(...)` les retirait) : validation du chemin par jq sur la chaîne d'origine, ancres `\A` et `\z` (`$` accepte un saut de ligne final, vérifié) ;
  - `MultiEdit` refusé (absent des outils du subagent) ;
  - nom du subagent vérifié en CI (CA13), `<plugin>:learning-curator` traité comme `learning-curator` ;
  - limites du README : dépendance au champ `agent_type`, coût du matcher `*` ;
  - un seul appel à jq pour les autres agents, message « jq absent » aligné sur `protect-secrets.sh`, barre finale de `CLAUDE_PROJECT_DIR` tolérée, test d'un `Edit` sur un piège existant, CA25 rangé après CA21, CA20 précisé « pour learning-curator », historique retiré de la consigne de revue et de l'en-tête du hook.
- Tests : 60 cas au vert. Mutation : 21 protections, 20 tuées ; survivant : `file_path` absent, équivalent (déjà noté).
- Test réel (CA24) refait sur la version finale : même résultat (README refusé, piège accepté, session principale libre).

### Décisions

- Agent : suggestion « casse insensible du système de fichiers » non suivie, impact nul tant que `docs/learnings/` ne contient que des pièges.

### Corrections et limites

- Le job « Revue IA » de cette PR sera rouge : elle modifie `ai-review.yml`, que `claude-code-action` refuse de relire (README, « Garde-fous »). CA14 (lecture de la description en CI) ne se vérifiera qu'à la PR suivante ; relecture humaine obligatoire.

### Prochaine étape

- PR #42 ouverte. Après son merge : vérifier CA14 sur la PR suivante, et reprendre la branche dans FieldOps.
