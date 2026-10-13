# Journal : spec 007, un modèle choisi pour chaque subagent, et ADR-005

Branche `docs/spec-007-modele-par-agent`.

## 2026-10-13 11:10

### Fait

- Spec 007 au statut « brouillon » : modèle déclaré par chaque subagent (`test-writer` et `learning-curator` en `sonnet`, `reviewer` et `security-reviewer` en `opus`), vérification par un nouveau `verifier-modeles.sh` dans `garde-fous.yml`, modèle de la revue IA en CI lu dans `reviewer.md`, skills sans modèle. 18 critères d'acceptation.
- ADR-005 au statut « proposé » : critère de choix (juger → `opus`, exécuter → `sonnet`, mécanique → `haiku`) et alias plutôt qu'identifiants figés.
- Fonctionnement du champ `model` vérifié dans la documentation de Claude Code (`sub-agents`, `skills`, `github-actions`, `model-config`, 2026-10-13).

### Décisions

- Un modèle par subagent, alias plutôt qu'identifiant figé (Yanis).
- `learning-curator` en `sonnet` et non `haiku` : son filtre demande du jugement (agent, accepté par Yanis).
- `/review` ne déclare pas de modèle : la documentation ne dit pas lequel l'emporte entre le skill `context: fork` et le subagent ; le test humain CA18 le vérifie (agent).
- `fable` hors de la liste autorisée tant qu'il n'est pas évalué (agent, à valider par Yanis).

### Corrections et limites

- Le paramètre `model` passé à l'invocation l'emporte sur l'en-tête : la règle « jamais de paramètre `model` » est une consigne, pas une protection technique.
- Aucun coût mesuré : la spec et l'ADR n'avancent aucun chiffre.

### Prochaine étape

- Relecture de la spec 007 et de l'ADR-005 par Yanis, réponse à la question ouverte (repli sans `opus`), puis `/implement docs/specs/007-modele-par-agent.md`.
