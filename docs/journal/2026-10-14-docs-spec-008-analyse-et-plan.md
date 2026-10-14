# Journal : spec 008, analyse du besoin et plan global

Branche `docs/spec-008-analyse-et-plan`.

## 2026-10-14 16:01

### Fait

- Spec 008 au statut « brouillon » : skill `/analyse` (cahier des charges, architecture technique, plan), modèle `docs/templates/plan.md`, plan versionné dans `docs/plan.md` et coché par la PR qui fait le travail, création du plan par `init.sh`, premier lot non coché affiché par `session-start.sh`. 15 critères d'acceptation.
- Constats repris des frictions notées dans le plan de Tidemark (plan local non versionné, analyse faite à la main).

### Décisions

- Fonctionnalités listées par l'analyse, spec rédigée juste avant chaque lot (Yanis).
- Plan versionné dans `docs/plan.md`, coché dans la PR qui réalise la tâche (Yanis).
- Deux specs : 008 pour l'analyse et le plan, 009 pour l'étape design system et maquette (Yanis).
- Statut des fonctionnalités laissé au cahier des charges, le plan y renvoie, pour respecter « une information à un seul endroit » (agent, à valider par Yanis).
- Affichage du plan par `session-start.sh` (CA4 à CA6) : proposé par l'agent, en question ouverte.

### Corrections et limites

- Les CA des skills (CA9 à CA15) ne se testent qu'à la main, sur un projet jetable : une skill est une consigne, pas du code.

### Prochaine étape

Yanis relit la spec 008 et répond aux trois questions ouvertes. Ensuite : spec 009 (étape design), puis `/implement docs/specs/008-analyse-et-plan-global.md`.
