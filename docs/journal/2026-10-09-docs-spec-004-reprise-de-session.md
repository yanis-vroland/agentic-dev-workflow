# Journal : spec 004, reprise de session sans mémoire locale

Branche `docs/spec-004-reprise-de-session`, PR #32.

## 2026-10-09 16:34

### Fait

- Spec 004 rédigée, puis validée par Yanis.
- Tests écrits par un subagent `test-writer` et committés en échec (76b46cc) : 34 échecs pour `tests/session-start.sh`, 30 pour `tests/verifier-journal.sh`, 19 pour `tests/init-script.sh`.
- Implémentation (70616d4) : `session-start.sh`, `verifier-journal.sh`, job CI « Journal », `autoMemoryEnabled: false`, `init.sh`. Tous les tests passent.
- Contrôle par mutation : 9 mutations, toutes détectées (fichier mergé modifié accepté, diff sans ancêtre commun, ordre chronologique ignoré, date non validée, ancien journal recréé, titres non contrôlés, mise à jour malgré des modifications, rebase automatique, code de sortie non nul).
- Ancien `docs/journal.md` déplacé dans `docs/journal/2026-10-07-historique.md`.

### Décisions

- Titres d'entrée à l'heure locale (Yanis).
- Entrée de journal exigée par `CLAUDE.md` et vérifiée par le reviewer, pas par la CI (proposition de l'agent, appliquée faute de réponse explicite de Yanis : à confirmer à la relecture).
- Spec, tests et code dans une seule PR, sans attendre le merge de #31, pour ne pas empiler les PR (agent).

### Corrections et limites

- Test CA2 renforcé par l'agent principal : le retard n'était pas vérifié, seulement les modifications non committées.
- Le fragment « gh » du test des PR ouvertes n'était pas convenu au départ : accepté, la sortie le contient.
- Mutation « fichier mergé modifié accepté » : seul le cas de la modification échoue. Suppression et renommage restent refusés par un autre chemin (fichier illisible dans `head`).

### Prochaine étape

- Après le merge de #31 : rebaser cette branche sur `main` et résoudre les conflits attendus dans `init.sh`, `tests/init-script.sh`, `README.md` et `CLAUDE.md`.
- Ajouter la vérification « Journal » au ruleset de `main`, après le merge (action manuelle de Yanis).
- Reporter dans FieldOps : fichiers de la chaîne, `settings.json`, migration de `docs/journal.md` et de sa section « Prochaines étapes ».
