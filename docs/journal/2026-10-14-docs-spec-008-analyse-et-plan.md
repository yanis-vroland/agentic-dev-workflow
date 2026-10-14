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

## 2026-10-14 16:15

### Fait

- Spec 008 renommée `008-cadrage-et-plan-global.md` et réécrite selon les réponses de Yanis : skill `/cadrage` ; cadrage imposé par l'agent dès les premières sessions (état détecté par `session-start.sh`, règle dans `CLAUDE.md`) ; étape suivante du plan proposée à chaque session et lancée après accord ; `disable-model-invocation` retiré de `/spec` et `/implement` ; besoin lu dans des documents fournis par l'humain. 21 critères d'acceptation.

### Décisions

- Nom `/cadrage`, skills lancées par l'agent sans commande à taper, besoin donné par des documents (Yanis).
- Détection « non cadré » par la présence de « À ADAPTER » dans le cahier des charges : FieldOps et Tidemark, déjà cadrés, ne sont pas bloqués (agent, à valider par Yanis).
- Accord de l'humain avant chaque skill lancée par l'agent ; points de contrôle d'ADR-002 inchangés (agent, à valider par Yanis).
- Sources non copiées dans le dépôt par défaut, listées dans une nouvelle section « Sources » du cahier des charges : elles peuvent contenir des données d'un client (agent, à valider par Yanis).
- Pas de hook qui refuse le code avant le cadrage : la règle de `CLAUDE.md` suffit tant qu'aucun contournement n'est constaté (agent, à valider par Yanis).

### Corrections et limites

- Le blocage avant cadrage repose sur une consigne, pas sur une protection technique : un agent peut l'ignorer. Le CA12 le vérifie à la main.
- L'implémentation modifiera l'ADR-004 (invocation des skills), déjà accepté : sa mise à jour sera à valider par Yanis.

### Prochaine étape

Yanis relit et valide la spec 008. Ensuite : implémentation de la spec 008.
