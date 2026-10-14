# Journal : cadrage d'un projet client, sans anonymisation

Branche `fix/cadrage-projet-client`.

## 2026-10-14 20:26

### Fait

- Skill `cadrage`, étape 2 « Stockage » à la place de « Confidentialité » : projet client gardé en local ou en dépôt privé, noms du client, du produit et des personnes utilisés tels quels ; documents de besoin copiés et versionnés dans `docs/sources/` ; avertissement unique avant le premier push si le dépôt est public. Retrait de l'anonymisation, de la liste à valider avant le push et de l'alerte sur les métadonnées.
- Modèle du cahier des charges : section « Sources » alignée.
- Spec 008 : principe de stockage, CA23 et cas limite « dépôt public » réécrits.

### Décisions

- Plus d'anonymisation : un projet client est un fork du template, gardé en local ou dans un dépôt privé, et ses specs nomment le client et le produit (Yanis).
- Avertissement conservé si le dépôt est public, une seule fois, sans rien bloquer d'autre : c'est la condition même de la décision (agent, à valider par Yanis).

### Corrections et limites

- Les points 1 et 2 de la revue IA de la PR #46 (fuite de noms avant l'accord, branches et PR non couvertes) deviennent sans objet.
- Les documents versionnés dans `docs/sources/` (PDF, Word) alourdissent l'historique Git.
- CA23 réécrit sans nouveau test : il se vérifie à la main, comme les autres CA de la skill.

### Prochaine étape

Yanis relit et merge. Ensuite : implémentation de la spec 009.
