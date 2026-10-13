# Spec 007 : un modèle choisi pour chaque subagent

Statut : validée
Date : 2026-10-13

## Besoin

En tant que développeur qui confie du travail à la chaîne, je veux que chaque subagent, présent ou futur, déclare le modèle adapté à sa tâche, choisi selon un critère écrit, afin de payer le prix d'un modèle fort là où une erreur coûte cher (revue, sécurité) et pas ailleurs, et de pouvoir justifier chaque choix.

Constats d'origine (2026-10-13) :

- Aucun des quatre subagents (`test-writer`, `reviewer`, `security-reviewer`, `learning-curator`) ne déclare de modèle : tous prennent celui de la session, quelle que soit leur tâche.
- La revue IA en CI (`ai-review.yml`) ne passe pas `--model` : elle tourne avec le modèle par défaut de `claude-code-action`, qui peut différer de celui du `reviewer` en local, alors qu'elle applique les mêmes consignes.
- Rien n'oblige un subagent ajouté plus tard, dans le template ou dans un projet, à choisir son modèle.

Le template n'a ni cahier des charges ni architecture technique propres (spec 003, « Hors périmètre »), et pas encore de piège dans `docs/learnings/` : aucun n'a été relu pour cette spec.

## Principes

1. **Le modèle suit la tâche, selon un critère écrit** ([ADR-005](../adr/005-choix-du-modele-par-agent.md)) : exécuter une tâche bien cadrée → `sonnet` ; juger, ou trouver ce qui manque → `opus` ; tâche mécanique, sans jugement → `haiku`.
2. **Un choix explicite, vérifié par la CI.** Un subagent sans modèle, ou avec `inherit`, n'a pas été choisi : la CI le refuse, dans le template comme dans les projets.
3. **Une information à un seul endroit.** Le modèle du `reviewer` est écrit dans `reviewer.md` ; la revue IA en CI le lit là, au lieu de le recopier.
4. **La session principale reste à l'humain.** Les skills que l'humain lance (`/spec`, `/implement`) ne fixent pas de modèle : c'est lui qui choisit celui de sa session.

## Modèles des subagents du template

| Subagent | Modèle | Critère (ADR-005) |
| --- | --- | --- |
| `test-writer` | `sonnet` | Exécuter : écrire du code de test à partir de critères d'acceptation numérotés. |
| `reviewer` | `opus` | Juger : trouver ce qui manque ou contredit la spec. Une erreur ratée coûte plus qu'un appel. |
| `security-reviewer` | `opus` | Juger : imaginer un scénario d'exploitation. Une faille ratée est le pire cas. |
| `learning-curator` | `sonnet` | Le texte à écrire est cadré par un format, mais le filtre (« ce piège se généralise-t-il ? ») demande du jugement : pas `haiku`. |

## Déclaration et vérification

- **Déclaration** : une ligne `model:` dans l'en-tête de chaque fichier de `.claude/agents/`, avec un alias : `sonnet`, `opus` ou `haiku`. Pas d'identifiant complet (`claude-…`) : l'alias suit la dernière version du modèle (ADR-005).
- **Vérification** : nouveau script `.github/scripts/verifier-modeles.sh`, lancé par `garde-fous.yml`, donc dans le template et dans les projets. Pour chaque `.claude/agents/*.md`, il lit la ligne `model:` de l'en-tête, et échoue si elle est absente, vide, en double, égale à `inherit`, ou hors de la liste autorisée. Le message nomme le fichier, la valeur trouvée et la liste autorisée.
- **Justification** : la PR qui ajoute un subagent, ou change son modèle, donne le critère de l'ADR-005 appliqué, en une ligne. Le script ne peut pas le vérifier : c'est une règle de `CLAUDE.md`, relue en revue.
- **Invocation** : l'outil qui lance un subagent accepte un paramètre `model` qui **prend le pas** sur l'en-tête (documentation de Claude Code, `sub-agents`, 2026-10-13). `/implement`, `/review` et `CLAUDE.md` ne passent jamais ce paramètre, sauf pour une substitution décidée par l'humain (section suivante) : sinon l'en-tête ne serait plus la source du choix.

## Modèle indisponible : l'humain choisit le substitut

Le modèle déclaré peut être indisponible : abonnement sans accès, quota atteint, alias inconnu de la version installée de Claude Code.

- **En session** : l'agent principal ne choisit jamais de substitut lui-même et ne relance pas le subagent avec un autre modèle en silence. Il s'arrête et demande à l'humain quel modèle utiliser, en rappelant le subagent concerné, le modèle déclaré, l'erreur reçue et le critère de l'ADR-005 qui justifiait ce modèle.
- La réponse de l'humain vaut **pour la session en cours** : l'agent relance le subagent avec le paramètre `model` choisi. C'est la seule exception à l'interdiction de ce paramètre. L'en-tête du subagent n'est pas modifié.
- La substitution est consignée dans la rubrique « Corrections et limites » du journal de la branche (subagent, modèle déclaré, substitut, décidé par l'humain), et dans la PR, section « Points d'attention » : une revue faite par un modèle plus faible que prévu doit se voir.
- **Changement durable** (un projet qui n'aura jamais accès à `opus`) : modification de l'en-tête par une PR qui justifie l'écart à l'ADR-005, jamais par une substitution répétée à chaque session.
- **En CI** : personne ne peut répondre. La revue IA échoue avec un message qui nomme le modèle demandé et indique les deux sorties possibles : relancer plus tard (quota) ou changer le modèle de `reviewer.md` par une PR. Elle ne bascule jamais sur un autre modèle.

## Revue IA en CI

- Une étape avant la revue lit `model:` dans `.claude/agents/reviewer.md`, la vérifie contre la même liste autorisée, et la passe à `claude-code-action` par `--model` dans `claude_args`. Valeur absente ou hors liste : l'étape échoue, la revue ne tourne pas.
- La valeur n'est jamais recopiée en dur dans `ai-review.yml`.

## Skills

- `/spec` et `/implement` : pas de `model`, ils tournent avec le modèle de la session.
- `/review` (`context: fork`, `agent: reviewer`) : pas de `model` dans le skill. La documentation ne dit pas lequel l'emporte quand le skill et le subagent en déclarent chacun un : n'en déclarer qu'un, celui du subagent, évite la question.

## Critères d'acceptation

### Script de vérification (nouveau `tests/verifier-modeles.sh`)

- CA1 : Étant donné des subagents qui déclarent tous `model: sonnet`, `opus` ou `haiku`, quand le script s'exécute, alors il sort avec le code 0.
- CA2 : Étant donné un subagent sans ligne `model:`, quand le script s'exécute, alors il sort avec un code non nul, et stderr nomme le fichier.
- CA3 : Étant donné un subagent avec `model: inherit`, `model:` vide, ou un identifiant complet (`model: claude-opus-5-5`), quand le script s'exécute, alors il échoue, et stderr nomme le fichier, la valeur trouvée et la liste autorisée.
- CA4 : Étant donné un subagent avec deux lignes `model:` dans l'en-tête, quand le script s'exécute, alors il échoue.
- CA5 : Étant donné une ligne `model: opus` dans le corps du fichier (après la fin de l'en-tête) et aucune dans l'en-tête, quand le script s'exécute, alors il échoue : seule compte la ligne de l'en-tête.
- CA6 : Étant donné plusieurs subagents dont deux invalides, quand le script s'exécute, alors stderr nomme les deux fichiers (pas d'arrêt au premier).
- CA7 : Étant donné un dossier `.claude/agents/` absent ou vide, quand le script s'exécute, alors il sort avec le code 0.
- CA8 : Étant donné des espaces en fin de ligne (`model: opus  `) ou une fin de ligne CRLF, quand le script s'exécute, alors la valeur est reconnue.

### Subagents du template

- CA9 : Les quatre subagents du template déclarent le modèle du tableau « Modèles des subagents du template », et `verifier-modeles.sh` passe sur le template.

### Revue IA en CI

- CA10 : `ai-review.yml` passe à `claude-code-action` un `--model` lu dans `.claude/agents/reviewer.md`, et ne contient aucun nom de modèle en dur. La CI du template le vérifie.
- CA11 : Étant donné un `reviewer.md` dont le modèle est absent ou hors liste, quand l'étape de lecture du modèle s'exécute, alors elle échoue avant la revue. La logique de lecture et de validation est celle de `verifier-modeles.sh` (une seule implémentation), testée par CA1 à CA8.
- CA11 bis : Étant donné une revue IA en CI qui échoue parce que le modèle est indisponible, quand le job se termine, alors son message nomme le modèle demandé et les deux sorties (relancer, ou changer `reviewer.md` par une PR), et aucun autre modèle n'a été essayé. Vérifié par l'humain sur un échec réel ou provoqué (modèle inconnu dans une branche de test), faute de pouvoir simuler l'indisponibilité en test automatique.

### Branchement et `init.sh`

- CA12 : `garde-fous.yml` lance `verifier-modeles.sh` et `tests/verifier-modeles.sh`, et shellcheck vérifie les deux.
- CA13 : Étant donné une cible vide, quand je lance `init.sh`, alors `.github/scripts/verifier-modeles.sh` et `tests/verifier-modeles.sh` sont copiés (ajout à `tests/init-script.sh`).

### Contrôle par mutation (règle n°2 de `CLAUDE.md`)

- CA14 : Chaque protection est désactivée une fois, et au moins un test échoue : refus de la ligne absente, refus de `inherit`, refus d'une valeur hors liste, refus du doublon, limitation à l'en-tête, poursuite après le premier fichier invalide, lecture du modèle par `ai-review.yml`.

### Relecture humaine (consignes, non testables automatiquement)

- CA15 : `CLAUDE.md` contient la règle : tout subagent ajouté déclare un `model` choisi selon l'ADR-005, justifié en une ligne dans la PR, et aucun subagent n'est invoqué avec un paramètre `model`.
- CA15 bis : `CLAUDE.md` et `/implement` décrivent la conduite face à un modèle indisponible : arrêt, question à l'humain avec le subagent, le modèle déclaré, l'erreur et le critère de l'ADR-005 ; substitut appliqué à la seule session ; consignation dans le journal et la PR.
- CA16 : `/implement` et `/review` n'invoquent aucun subagent avec un paramètre `model`, hors substitution décidée par l'humain ; `/spec`, `/implement` et `/review` ne déclarent pas de `model`.
- CA17 : Le README (garde-fous, limites, structure) renvoie à l'ADR-005 et indique le modèle de chaque subagent.
- CA18 : Test humain : dans une session Claude Code lancée avec `sonnet`, `/review` est lancé ; l'humain constate, dans la sortie ou dans `/agents`, que le `reviewer` tourne avec `opus`. Ce contrôle couvre le point non documenté du skill `context: fork` avec `agent:`.

## Cas limites et erreurs

- Variable `CLAUDE_CODE_SUBAGENT_MODEL` définie sur un poste : selon la documentation, elle passe **après** l'en-tête, donc ne change pas le modèle d'un subagent qui en déclare un. Rien à faire.
- Variables `ANTHROPIC_DEFAULT_OPUS_MODEL` (et équivalentes) : elles redirigent un alias vers un autre identifiant, par exemple chez un fournisseur tiers (Bedrock, Vertex). C'est voulu : le template déclare un niveau, le poste ou l'organisation choisit l'identifiant.
- Modèle indisponible : voir « Modèle indisponible : l'humain choisit le substitut ». L'humain peut aussi répondre de ne pas lancer le subagent : l'agent le consigne comme une étape sautée (journal et PR), sans la présenter comme faite.
- L'humain choisit un substitut hors de la liste autorisée (un identifiant complet, `fable`) : accepté pour la session, puisque c'est son choix et que l'en-tête ne change pas ; `verifier-modeles.sh` ne voit que les en-têtes.
- Subagent ajouté par un plugin ou dans `~/.claude/agents/` : hors du dépôt, non vérifié.
- En-tête sans ligne `---` de fermeture, ou fichier passé en argument mais inexistant : refus, avec le nom du fichier.
- Valeurs refusées par la règle « alias nu, en minuscules » : `"opus"` entre guillemets, `Opus`, `fable`. Une ligne `model:` suivie seulement d'espaces vaut une valeur vide.
- Fichier de `.claude/agents/` qui n'est pas un subagent (README, par exemple) : `verifier-modeles.sh` le refuse aussi. Les fichiers de ce dossier sont tous des subagents ; un autre fichier n'a rien à y faire.

## Hors périmètre

- Mesure du coût ou de la qualité par modèle : aucun chiffre n'est annoncé avant d'avoir mesuré. La mesure demande un jeu de PR de référence, à décider à part.
- Choix du modèle de la session principale : il reste à l'humain (`/model`, `--model`, réglages personnels).
- Niveau de raisonnement (`effort`) par subagent : à évaluer à part si le besoin apparaît.
- Alias `fable` : documenté par Claude Code, mais pas évalué sur cette chaîne. Il n'entre dans la liste autorisée qu'après un amendement de l'ADR-005.

## Décisions (Yanis, 2026-10-13)

1. Un modèle par subagent, selon le critère de l'ADR-005, avec des alias.
2. Modèle indisponible : l'agent demande à l'humain quel substitut utiliser, il ne choisit jamais seul.

## Questions ouvertes

- Aucune.
