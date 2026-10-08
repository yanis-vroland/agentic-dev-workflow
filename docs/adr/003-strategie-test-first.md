# ADR-003 : Stratégie test-first

Statut : proposé
Date : 2026-10-08

Contexte : `CLAUDE.md` impose le test-first (règle n°2) et interdit d'affaiblir un test sans le signaler (règle n°3). Il reste à décider qui écrit les tests et comment s'assurer qu'ils protègent vraiment. Constats des lots A à D :
- Le subagent `test-writer`, chargé d'écrire les tests à partir des critères d'acceptation, a produit pour `init.sh` des tests justes sur la forme : 118 échecs avant implémentation. Mais plusieurs vérifications passaient d'office, parce qu'elles cherchaient un nom de fichier que la sortie affichait de toute façon.
- Le contrôle par mutation (casser volontairement le code et vérifier qu'un test échoue) a trouvé des trous que ni les tests ni la relecture n'avaient vus. Trois exemples :
  - une insertion désactivée dans le `.gitignore` (lot C) ;
  - un `grep` manquant qui laissait passer l'action (#7) ;
  - un compteur non numérique accepté sans erreur (#9).
- Un test du lot A, qui pouvait passer avec un hook défaillant (PR #4), n'a été repéré que par la revue IA, après coup.

Options envisagées :
- Tests écrits après le code, par l'agent qui implémente : simple, mais ils risquent de confirmer le code au lieu de la spec.
- Test-first par l'agent qui implémente : les tests précèdent le code, mais leur auteur connaît déjà l'implémentation qu'il va écrire.
- Test-first par un subagent dédié, à partir des seuls critères d'acceptation, avec relecture critique des tests par l'agent principal et contrôle par mutation sur les garde-fous.

Décision : test-first par un subagent dédié, relu et éprouvé par mutation.
- Le subagent `test-writer` écrit les tests à partir des critères d'acceptation de la spec, jamais à partir du code. Chaque test cite son critère (CA1, CA2…).
- On vérifie que les tests échouent, et pour la bonne raison (fonctionnalité absente, pas erreur de syntaxe). Ils sont committés avant l'implémentation, dans un commit séparé.
- L'agent principal relit les tests avant d'implémenter. Toute vérification qui passerait sans implémentation, hors vérifications négatives, est renforcée.
- Renforcer un test est permis, et se signale dans la PR. L'affaiblir ou le supprimer exige un signalement explicite (règle n°3).
- Contrôle par mutation obligatoire sur les garde-fous (hooks, scripts de sécurité, vérifications de CI) : chaque protection est désactivée une fois, et au moins un test doit échouer. Une mutation non détectée donne un test supplémentaire.
- Pour une correction (fix), le test de non-régression est écrit avant la correction, et échoue avant elle (règle n°1).
- Les tests vérifient les codes de sortie, les effets et des fragments de message, jamais le texte exact.

Conséquences :
- Plus de commits par PR (spec, tests rouges, implémentation), mais l'historique montre que les tests ont précédé le code.
- Le contrôle par mutation est manuel : aucun outil de mutation n'est en place pour les scripts shell. Il coûte du temps, d'où sa limitation aux garde-fous.
- Le subagent ne suffit pas seul : la qualité des tests dépend de la relecture de l'agent principal, et en dernier ressort de l'humain (ADR-002).
