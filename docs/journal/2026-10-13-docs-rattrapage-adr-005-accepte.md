# Journal : docs/rattrapage-adr-005-accepte

Branche `docs/rattrapage-adr-005-accepte`.

## 2026-10-13 15:10

### Fait

- Constat : la PR #39 a été mergée avant le push de son dernier commit (`e5dcdc1`, « ADR-005 accepté, test humain validé »). Ce commit n'est pas sur `main`.
- Report sur `main` des changements de `e5dcdc1` : ADR-005 au statut « accepté », mention « proposé » retirée de la spec 007, ligne spec 007 / ADR-005 dans « Specs et décisions » du README.
- L'entrée de journal de 15:00 de l'ancienne branche n'est pas reportée : son fichier est déjà mergé, la CI en refuse la modification. Elle reste lisible dans le commit `e5dcdc1`.

### Décisions

- Yanis : rattrapage par une PR dédiée plutôt que de laisser l'ADR-005 au statut « proposé » sur `main`.

### Corrections et limites

- Cause : la vérification « dernier commit sur `main` » (règle 6 de `CLAUDE.md`) n'est faite qu'après le merge ; ici, le merge a eu lieu entre le commit local et son push. La règle n'est pas modifiée : elle a bien détecté l'écart, après coup.

### Prochaine étape

- Relecture et merge par Yanis, puis vérification que le dernier commit de cette PR est sur `main`.
