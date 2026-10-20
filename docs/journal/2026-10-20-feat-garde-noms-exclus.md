# Journal : garde-fou des noms exclus, spec 010

Branche `feat/garde-noms-exclus`.

## 2026-10-20 09:30

### Fait

- Spec 010 rédigée au statut brouillon, à partir de trois frictions constatées sur Tidemark les 2026-10-16 et 2026-10-20 : le garde-fou arrivé au quatrième jour sur 36 PR déjà mergées ; la fuite venue d'une trace de contrôle qui citait les noms cherchés ; le dépôt passé en public alors que la réécriture de l'historique était inscrite comme préalable depuis quatre jours.
- Périmètre proposé : le script et ses tests dans le socle copié par `init.sh`, un contrôle avant publication, la règle de rédaction des traces de contrôle, et le contrôle par mutation.
- Aucun test ni code écrit : la spec attend la validation de Yanis (méthode de travail, règle 1).

### Décisions

- Aucune. Deux questions ouvertes laissées à Yanis : découper ou non la PR, et rétroporter ou non dans Tidemark et FieldOps.

### Corrections et limites

- Le contrôle avant publication ne peut pas empêcher `gh repo edit --visibility public` : il constate, l'humain décide (ADR-002). C'est une limite assumée, écrite dans la spec.
- `docs/learnings/` est vide : aucun piège relu pour cette spec.

### Prochaine étape

- Validation de la spec par Yanis, puis tests par le subagent `test-writer`, puis implémentation.
