# Journal : rattrapage de la revue de sécurité de la spec 006

Branche `fix/spec-006-revue-securite`.

## 2026-10-12 13:45

### Fait

- La PR #37 a été mergée sur d3666b6, avant que les quatre derniers commits de sa branche soient poussés. Repris ici depuis `main` :
  - tests de non-régression de la revue de sécurité (c8eb709) et du lint des fichiers sourcés (af16026), rouges avant correction ;
  - corrections (14a9431) : sortie du lint et des tests délimitée comme des données, lien symbolique vers l'extérieur ni formaté ni linté, chemin vérifié transmis à `format.sh`, avertissement quand la marque ne peut pas être posée, identifiant de session raccourci, `shellcheck -x` dans `scripts/lint-shell.sh` ;
  - limite du README : modifier un fichier revient à exécuter du code sans demande.
- Contenu des deux dernières entrées du journal de #37, qui ne peut plus être modifié après son merge : revue de sécurité (rien de bloquant, un « À corriger » documenté, trois suggestions corrigées), mutation (23 protections détectées, une mutation équivalente sur le chemin transmis à `format.sh`), test humain positif sans boucle négative (« je valide »).

### Décisions

- Exécution sans demande du code écrit par l'agent : documentée dans les Limites, sans interdiction de modifier `.claude/hooks/` ni `.claude/quality.json` (lu comme accepté dans « je valide », Yanis, à confirmer).
- Rattrapage dans une nouvelle PR basée sur `main` plutôt que de rouvrir #37, dont le journal est mergé (agent).

### Corrections et limites

- Écart à la règle n°6 de `CLAUDE.md` : l'agent a annoncé la PR #37 prête puis poussé des commits après le merge, sans vérifier que le dernier commit était sur `main`. Constaté à la fin de la session.
- Le subagent `security-reviewer` n'était pas chargé dans la session : la revue a été faite par un agent généraliste qui appliquait ses consignes avec les mêmes outils.

### Prochaine étape

- Relecture et merge de cette PR par Yanis, puis vérifier que son dernier commit est sur `main`.

## 2026-10-12 13:48

### Fait

- PR #38 ouverte. CI verte, revue IA publiée : rien de bloquant, cinq « À corriger », cinq suggestions. Pas encore de réponse : Yanis clôt la session.
- Correspondance des SHA : c8eb709, af16026 et 14a9431 (branche de #37, non mergés) sont repris ici en 2b8be8f, 5c7074a et b83d576.

### Décisions

- Corrections reportées à la prochaine session (Yanis clôt la session).

### Corrections et limites

- Rien de nouveau.

### Prochaine étape

- Traiter la revue IA de #38, puis publier « Réponse à la revue IA » (règle n°5) :
  1. compléter la spec 006 avec des critères pour les cas révélés par la revue de sécurité (lien symbolique vers l'extérieur, avertissement sans marque, identifiant long, sorties délimitées, lint d'un fichier sourcé), et renommer les tests « Sécurité : … » avec leur numéro de critère ;
  2. documents de référence : non fondé sur le template (spec 003), à expliquer ;
  3. demander à Yanis un test humain des corrections (lien symbolique, avertissement hors Git, sortie délimitée) ;
  4. tester le marqueur de fin de la sortie des tests ;
  5. `lint.sh` valide désormais aussi la clé `test` et ne pose plus la marque si `quality.json` est invalide : tester et documenter, ou revenir à l'ancien ordre.
- Suggestions à considérer : lien symbolique vers un fichier du projet et chaîne de liens, test « projet sans Git » isolé par `GIT_CEILING_DIRECTORIES`, marqueur de fin aléatoire.
- Décision de Yanis à consigner : pas d'interdiction de modifier `.claude/hooks/` ni `.claude/quality.json` (confirmer ou non).
