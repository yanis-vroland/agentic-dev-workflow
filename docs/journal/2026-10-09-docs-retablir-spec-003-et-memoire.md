# Journal : spec 003 rétablie, mémoire locale reportée dans CLAUDE.md

Branche `docs/retablir-spec-003-et-memoire`.

## 2026-10-09 16:42

### Fait

- Rétabli trois lignes de la spec 003 perdues à la résolution du conflit entre #31 et #32 : la spec 003 dans la liste `git rm` du README, les documents de référence dans la description de `init.sh` du README, et dans la définition du « done » de `CLAUDE.md`.
- Reporté dans `CLAUDE.md` les règles qui n'existaient que dans la mémoire locale de l'agent : réponses en français même pour les messages intermédiaires, et pas d'issue ni de label sans accord, sauf `bug`. Les règles sur les ADR et sur la réponse à la revue IA y étaient déjà (n°4 et n°5).
- Oubli corrigé en test-first : l'étape « ruleset » de `init.sh` et le README ne citaient pas la vérification « Journal » (spec 004, CA21 ajouté). Un projet initialisé ne l'aurait jamais exigée.
- GIF de démonstration régénéré puis écarté : les lignes affichées n'ont pas changé.

### Décisions

- La mémoire locale de l'agent pour ce dépôt est supprimée une fois cette PR mergée (spec 004).

### Corrections et limites

- Perte constatée après le merge de #32 : les tests passaient, car les lignes perdues étaient de la documentation, que ni la CI ni les tests ne vérifient. Une PR qui modifie les mêmes fichiers qu'une PR encore ouverte devrait être rebasée par l'agent avant le merge, au lieu de laisser la résolution du conflit à l'humain.

### Prochaine étape

- Après le merge : supprimer la mémoire locale de l'agent pour ce dépôt, puis reporter la chaîne dans FieldOps (fichiers de la chaîne, `settings.json`, migration de `docs/journal.md`, mémoire locale de FieldOps reportée dans son `CLAUDE.md`).
