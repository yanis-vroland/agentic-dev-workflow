# Guide d'adoption en équipe

Comment introduire ce template dans une équipe qui développe déjà, sans changer toute sa façon de travailler d'un coup.

> **Avertissement** : le template n'est pas encore éprouvé sur un projet réel (voir le statut du [README](../README.md)). Ce guide décrit l'organisation qu'il prévoit. Il ne rapporte pas de retour d'expérience, et ne promet aucun gain.

## Avant de commencer

- Lire `CLAUDE.md`, l'[ADR-002](adr/002-place-revue-humaine.md) (place de la revue humaine) et l'[ADR-003](adr/003-strategie-test-first.md) (stratégie test-first). Ils fixent les règles que l'agent applique.
- Installer les prérequis sur chaque poste (README, section « Prérequis »). Sans jq, les hooks de Claude Code refusent toutes les actions surveillées ; sans gitleaks, le pre-commit refuse tous les commits.
- Appliquer le template : `scripts/init.sh` pour un dépôt existant, « Use this template » pour un nouveau (README, section « Installation »).
- Configurer GitHub : application Claude, secret, ruleset sur `main`, label `agent-corrigé` (README, section « Configuration GitHub »).

## Rôles

| Rôle | Responsabilités |
| --- | --- |
| Auteur du besoin | exprime le besoin, répond aux questions de la spec |
| Valideur de spec | passe la spec au statut « validée » ; sans cette validation, l'agent n'implémente pas une fonctionnalité ni une correction |
| Relecteur | relit chaque PR selon l'ADR-002, coche « Ce que l'humain a vérifié », pose le label `agent-corrigé` dès que du code de l'agent a été refusé ou corrigé |
| Mainteneur | merge (l'agent ne merge jamais), tranche les choix structurants, valide les ADR proposés par l'agent |

Une même personne peut tenir plusieurs rôles. Ce qui compte : chaque PR a un humain identifié qui la relit et la merge.

## Rituels

- **Validation de spec** : la spec (`docs/specs/`, modèle `docs/templates/spec.md`) est relue avant tout code. Ses critères d'acceptation deviennent les tests ; une spec floue donne des tests faibles.
- **Relecture de PR selon l'ADR-002** :
  - relecture intégrale du diff dans les cas listés par l'ADR-002, qui fait foi : notamment quand la revue IA n'a pas tourné (job « Revue IA » rouge), ou quand la PR touche aux garde-fous ou aux secrets ;
  - sinon, relecture guidée par le rapport de la revue IA, la réponse de l'agent et la section « Points d'attention » de la PR.
- **Réponse aux revues IA** : chaque point du rapport reçoit une suite écrite dans la PR (corrigé, non suivi et pourquoi, reporté). Une revue IA ne relit que l'ouverture de la PR ; les commits de correction relèvent du relecteur humain.
- **Validation des ADR** : l'agent peut rédiger un ADR au statut « proposé ». Le mainteneur le relit, le modifie si besoin, le passe à « accepté », puis merge.

## Le label `agent-corrigé` comme indicateur

Le label marque une PR où du code de l'agent a été refusé ou corrigé par un humain. Il sert à :

- retrouver les corrections pour en comprendre la cause (spec incomplète, test trop faible, consigne manquante dans `CLAUDE.md`) ;
- repérer les zones où l'agent se trompe souvent, et y renforcer les règles ou les tests.

Il ne mesure rien si l'équipe ne le pose pas systématiquement. Ce n'est pas une note de performance de l'agent ni des personnes.

## Le journal de bord

`docs/journal.md` consigne ce que l'agent a bien fait, ce qui a été corrigé et pourquoi, et les limites observées. Le lire ensemble à intervalle régulier permet de :

- décider des ajustements : une règle à ajouter à `CLAUDE.md`, un ADR à rédiger, un garde-fou à durcir ;
- garder une trace factuelle, utile pour juger s'il faut étendre ou réduire l'usage de l'agent.

## Démarrage progressif

1. **Un projet pilote** : appliquer le template à un seul dépôt, avec une ou deux personnes volontaires.
2. **Des changements simples d'abord** : chore, docs, petites corrections, avant des fonctionnalités entières.
3. **Bilan sur le journal et le label** : avant d'étendre, relire ensemble le journal et les PR `agent-corrigé` du pilote, et ajuster `CLAUDE.md` et les ADR.
4. **Extension** : étendre à d'autres dépôts une fois les règles stabilisées, en écrivant un ADR si l'organisation change (par exemple, réduire le périmètre de relecture intégrale de l'ADR-002).
