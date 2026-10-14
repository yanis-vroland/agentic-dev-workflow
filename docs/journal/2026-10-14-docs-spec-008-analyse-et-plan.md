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

## 2026-10-14 16:21

### Fait

- Spec 008 passée au statut « validée ».

### Décisions

- Spec 008 validée, avec les propositions de l'agent : 10 questions par tour et deux tours, sources non copiées par défaut, pas de hook bloquant, mise à jour de l'ADR-004 (Yanis).
- Implémentation dans cette même branche et PR (#44), comme pour la spec 007 : la règle n°6 interdit de baser une PR sur une autre non mergée (agent).

### Corrections et limites

- Aucune.

### Prochaine étape

Tests rouges des CA1 à CA11 par le subagent `test-writer`, commit séparé, puis accord de Yanis avant l'implémentation.

## 2026-10-14 16:30

### Fait

- Tests rouges des CA1 à CA11 écrits par le subagent `test-writer` : `tests/session-start.sh` (CA1 à CA5), `tests/init-script.sh` (CA6 à CA8), deux étapes de `template-ci.yml` (CA9, CA10). Aucune vérification existante modifiée (CA11).
- Résultat : 12 échecs attendus (CA1 à CA4, CA6, CA8, fonctionnalité absente) ; CA5 et CA7 passent déjà, normal pour des non-régressions. Les étapes CI CA9 et CA10 échouent sur le dépôt actuel (exécutées à la main). Les autres suites de tests restent vertes, shellcheck sans avertissement.

### Décisions

- CA5 vérifié sur toute la sortie du hook, plus strict que « après le journal » ; CA3 vérifie aussi que la seconde case ouverte n'est pas affichée (test-writer, accepté par l'agent).
- `test-writer` lancé comme subagent générique avec ses consignes et son modèle déclaré (`sonnet`) : la session était ouverte à la racine de l'espace de travail, où les subagents du dépôt ne sont pas chargés (agent).

### Corrections et limites

- CA4 repère la ligne d'état par différence avec la sortie sans plan : le libellé reste libre, comme la spec le demande.

### Prochaine étape

Accord de Yanis sur les tests rouges, puis implémentation : modèle `docs/templates/plan.md`, section « Sources », skill `cadrage`, hook, `init.sh`, `CLAUDE.md`, ADR-004, README.
