# ADR-005 : Choix du modèle par agent

Statut : accepté
Date : 2026-10-13

Contexte : les subagents du template n'ont pas de modèle déclaré et prennent celui de la session ([spec 007](../specs/007-modele-par-agent.md)). Leurs tâches n'ont pourtant ni la même difficulté ni le même coût d'erreur : écrire des tests à partir de critères numérotés n'exige pas le même modèle que trouver une faille que personne n'a signalée. Il faut un critère, pour que chaque choix se justifie au lieu de relever du goût, et pour que les subagents ajoutés plus tard suivent la même règle.

Claude Code permet de déclarer un `model` dans l'en-tête d'un subagent : un alias (`sonnet`, `opus`, `haiku`, `fable`), un identifiant complet (`claude-opus-5-5`) ou `inherit`. Le paramètre `model` passé à l'invocation l'emporte sur l'en-tête, qui l'emporte sur la variable `CLAUDE_CODE_SUBAGENT_MODEL`, puis sur le modèle de la session (documentation de Claude Code, `sub-agents` et `model-config`, consultée le 2026-10-13).

## 1. Critère de choix

| Nature de la tâche | Modèle | Exemple dans le template |
| --- | --- | --- |
| Juger, ou trouver ce qui manque, quand une erreur ratée coûte plus qu'un appel | `opus` | `reviewer`, `security-reviewer` |
| Exécuter une tâche bien cadrée (entrée précise, format imposé), avec une part de jugement | `sonnet` | `test-writer`, `learning-curator` |
| Tâche mécanique, sans jugement, où une erreur se voit tout de suite | `haiku` | aucun aujourd'hui |

En cas de doute entre deux niveaux, la question est : « si ce subagent se trompe, qui s'en aperçoit, et quand ? ». Si personne ne s'en aperçoit avant le merge, niveau supérieur.

Options envisagées :
- **Hériter partout (`inherit`)** : rien à maintenir, mais le coût et la qualité dépendent du modèle choisi pour la session, pas de la tâche. Un humain qui travaille avec `sonnet` aurait une revue de sécurité en `sonnet`.
- **Le plus fort partout** : qualité maximale, coût maximal, et rien à justifier. Ne montre aucun arbitrage.
- **Un modèle par tâche, selon un critère écrit** : retenu.

## 2. Alias ou identifiant figé

Options envisagées :
- **Identifiant complet** (`claude-opus-5-5`) : comportement reproductible, mais chaque nouvelle version demande une PR dans le template et dans chaque projet, et un identifiant retiré casse la chaîne.
- **Alias** (`opus`) : suit la dernière version sans intervention. Un même fichier peut donner un comportement différent après une mise à jour du modèle. Les variables `ANTHROPIC_DEFAULT_*_MODEL` permettent à un poste ou à une organisation de rediriger un alias vers un identifiant précis (fournisseur tiers, version figée), sans toucher au dépôt.

Décision (Yanis, 2026-10-13) : **alias**. Le template déclare un niveau de modèle, pas une version. Ce qui doit être reproductible (les garde-fous) l'est par les tests et la CI, pas par la version du modèle.

## Décision

- Chaque subagent déclare `model: sonnet`, `opus` ou `haiku`, choisi selon le critère ci-dessus. `inherit` et les identifiants complets sont refusés par la CI (`verifier-modeles.sh`, spec 007).
- La PR qui ajoute un subagent ou change son modèle cite la ligne du critère appliquée.
- Les subagents sont invoqués sans paramètre `model`, pour que l'en-tête reste la seule source du choix.
- Modèle déclaré indisponible : l'agent s'arrête et demande à l'humain quel substitut utiliser (décision de Yanis, 2026-10-13). Le substitut vaut pour la session, est passé par le paramètre `model` (seule exception) et est consigné dans le journal et la PR. En CI, la revue échoue sans essayer d'autre modèle.
- La revue IA en CI lit le modèle dans `reviewer.md`, au lieu de le recopier.
- Les skills lancés par l'humain (`/spec`, `/implement`) ne fixent pas de modèle : la session principale reste son choix.
- `fable` n'est pas dans la liste : pas évalué sur cette chaîne. L'ajouter demande d'amender cet ADR.

Conséquences :
- **Coût** : deux subagents sur quatre passent en `opus`, dont la revue IA de chaque PR en CI, sur le jeton d'abonnement (ADR-001). Le quota est consommé plus vite. Aucun chiffre n'est avancé : rien n'a été mesuré.
- **Dérive** : avec les alias, une nouvelle version de modèle peut changer le comportement d'un subagent sans changement dans le dépôt. Une revue qui trouve soudain plus ou moins de points est un signal à consigner dans le journal.
- **Disponibilité** : aucun repli automatique. En session, l'humain choisit le substitut, ce qui interrompt le travail mais rend visible une revue faite par un modèle plus faible que prévu. Un projet durablement sans accès à `opus` change ses déclarations par une PR et justifie l'écart.
- **Vérification limitée** : la CI vérifie qu'un modèle est déclaré et autorisé, pas qu'il est le bon. La justification relève de la revue humaine (ADR-002).
- **Dépendance à Claude Code** (ADR-004) : les alias et l'ordre de priorité sont propres à Claude Code ; un changement de leur contrat se voit au test humain de la spec 007 (CA18), pas en CI.
