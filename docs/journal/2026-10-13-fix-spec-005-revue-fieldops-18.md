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
