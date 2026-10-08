# ADR-002 : Place de la revue humaine

Statut : proposé
Date : 2026-10-08

Contexte : l'agent écrit le code, et chaque PR passe par une revue IA (`ai-review.yml`, qui applique `.claude/agents/reviewer.md`). Il faut décider ce que l'humain contrôle lui-même et ce qu'il peut déléguer à cette revue. Constats des lots A à D (PR #4 à #13) :
- La revue IA a relevé des défauts réels, par exemple un test qui passait avec un hook refusant tout (PR #4), et l'écart entre une spec et son implémentation (PR #11).
- Elle n'a produit **aucun rapport** sur 3 des 8 PR des lots (#4, #5, #6, #8, #10, #11, #12, #13 ; les numéros #7 et #9 sont des issues) : sur la #8, son rapport a été refusé par un hook ; sur la #10 et la #12, l'action est sautée quand une PR modifie son propre workflow. Jusqu'à la PR #12, le job restait vert malgré tout.
- Elle ne relit que l'ouverture de la PR, pas les commits de correction poussés ensuite.
- Les décisions qui ont le plus changé le résultat sont venues de l'humain. Exemples : la règle de spec réécrite par nature du changement plutôt que par préfixe, le fail-closed du hook `protect-secrets`, le parcours d'installation du README.
- Les cases « Ce que l'humain a vérifié » sont restées décochées sur 5 des 7 PR mergées qui en comportaient : #5, #6, #8, #10 et #13. Les PR #11 et #12 ont été cochées ; la #4 n'avait pas de cases.

Options envisagées :
- Relecture humaine intégrale de chaque PR : sûre, mais coûteuse. Elle rend la revue IA presque inutile.
- Revue IA seule, l'humain merge au vu du rapport : rapide. Mais une revue absente ou muette passe inaperçue, comme sur les PR #8, #10 et #12.
- Points de contrôle humains ciblés : l'humain valide ce qui engage (spec, décisions, merge). Il relit en entier ce que la revue IA ne couvre pas ou ce qui touche aux garde-fous, et s'appuie sur la revue IA pour le reste.

Décision : points de contrôle humains ciblés.
- L'humain valide la spec avant toute implémentation (statut « validée »), et tranche toute ambiguïté ou tout choix structurant que l'agent lui soumet.
- L'humain seul merge. L'agent ouvre la PR et ne la merge jamais.
- Relecture intégrale du diff obligatoire quand :
  - la revue IA n'a pas tourné ou a échoué (job « Revue IA » rouge) ;
  - la PR modifie les garde-fous : `.claude/`, `.githooks/`, `.github/`, `scripts/init.sh` ;
  - la PR touche à la gestion des secrets.
- Dans les autres cas, relecture guidée par le rapport de la revue IA, la réponse point par point de l'agent et la section « Points d'attention » de la PR.
- Avant le merge, l'humain coche « Ce que l'humain a vérifié », ou note ce qui n'a pas été vérifié. Il ajoute le label `agent-corrigé` si du travail de l'agent a été refusé ou corrigé.
- Les ADR peuvent être rédigés par l'agent, au statut « proposé ». Ils ne sont publiés (merge) qu'après validation humaine, avec modification si besoin.

Conséquences :
- Le temps humain se concentre sur les décisions et sur les zones où la revue IA est aveugle ou où une erreur coûte cher.
- La revue IA reste une aide, pas une barrière : elle n'est pas dans les vérifications requises du ruleset. C'est l'humain qui fait office de filet de sécurité.
- Le système repose sur la discipline de l'humain pour cocher les cases et poser le label. Sans elle, le label `agent-corrigé` ne mesure rien.
- « L'humain seul merge » est une règle de travail, pas une protection technique. Le ruleset de `main` impose une PR et des vérifications vertes, mais un agent qui dispose des droits de l'humain via `gh` pourrait merger.
- Si la revue IA s'avère fiable sur la durée, le périmètre de relecture intégrale pourra être réduit par un nouvel ADR. FieldOps, premier projet réel sur lequel le template sera appliqué, en donnera la mesure.
