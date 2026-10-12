# Journal : flux de la chaîne, historique de construction et ADR-004

Branche `docs/readme-flux-et-adr-004`.

## 2026-10-12 10:24

### Fait

- README, section « Le flux, de la spec au merge » : schéma Mermaid de `/spec` au merge humain, et tableau qui relie chaque étape à son fichier.
- README, section « Comment ce projet a été construit » : specs 001 à 005 et ADR avec leurs PR, ce que la revue IA a trouvé (#4, #28, #32) et manqué (#8, #10, #12), décisions humaines, mutations, écarts au processus. Emplacement réservé pour l'exemple FieldOps (#15).
- ADR-004 « choix de l'outil d'agent », statut « proposé » : Claude Code, Cursor, GitHub Copilot, Aider.

### Décisions

- Périmètre fixé par Yanis : README (schéma, historique) et ADR-004 dans une PR docs, sans spec ; #14, #15 et les points reportés de la fiche exclus.
- Le schéma suit les fichiers réels : `test-writer` et `learning-curator` sont dessinés dans `/implement`, qui les appelle, et non comme des étapes séparées (agent).
- Les écarts au processus (label `agent-corrigé` jamais posé, pas de réponse à la revue IA sur #31 à #35) sont écrits dans le README plutôt que tus (agent, à valider par Yanis).

### Corrections et limites

- Les fonctionnalités des autres outils de l'ADR-004 viennent de leur documentation (2026-10-12), pas d'un essai.
- Constatés, non corrigés ici : la spec 003 est restée au statut « brouillon » après le merge de #31 ; la contradiction entre la règle n°6 et « Reprise de session » sur le rebase, relevée par la revue IA de #34, est toujours dans `CLAUDE.md`.

### Prochaine étape

- Relecture de la PR par Yanis, validation ou modification de l'ADR-004, puis merge.

## 2026-10-12 10:29

### Fait

- Réponse à la revue IA de #36 : écarts au processus datés, phrase sous le schéma sur les étapes 2 et 10 de `/implement` qu'il omet.

### Décisions

- Pas d'issue créée pour la spec 003 et la contradiction sur le rebase : leur création revient à Yanis (agent).

### Corrections et limites

- Vérifiés : l'ancre `#configuration-github` existe ; l'ADR-001 parle déjà de Claude ; la CI du template vérifie les outils de `learning-curator`.

### Prochaine étape

- Relecture de la PR par Yanis, validation ou modification de l'ADR-004, puis merge.
