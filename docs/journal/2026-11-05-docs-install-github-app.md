# Journal : avertissement sur /install-github-app (issue #53)

Branche `docs/install-github-app`.

## 2026-11-05 20:43

### Fait

- README, « Configuration GitHub », étape 1 : `/install-github-app` propose ses propres workflows, qui doublent `ai-review.yml` ; consigne de ne pas les accepter. Ferme l'issue #53.

### Décisions

- Yanis : nettoyer le dépôt pour le présenter, « tout le reste d'un coup » (conversation du 2026-11-05).

### Corrections et limites

- Noms des deux workflows tirés de la documentation de l'application GitHub Claude, non revérifiés sur un dépôt neuf.

### Prochaine étape

- PR, revue IA, merge par Yanis.

## 2026-11-05 20:46

### Fait

- Revue IA de la PR #62 : rien de bloquant. Corrigé : le README distingue les deux workflows proposés (« Claude Code Review » double `ai-review.yml`, « @Claude Code » répond aux mentions `@claude` et n'est pas nécessaire), noms de fichiers donnés « par exemple » ; tableau des specs, spec 010 rattachée à #58 au lieu de #53, qui est une issue.
- Heure de l'entrée précédente recalée sur celle du commit (écrite à l'avance).

### Décisions

- Agent : non suivi dans cette PR, l'avertissement dans la tâche générée par `scripts/init.sh` : il change la sortie d'un script, hors d'une PR de documentation.

### Corrections et limites

- Aucune.

### Prochaine étape

- Réponse à la revue IA, merge par Yanis.
