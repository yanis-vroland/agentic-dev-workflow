# Journal : spec 009, design system et maquette entre la spec et les tests

Branche `docs/spec-009-design-et-maquette`.

## 2026-10-14 16:03

### Fait

- Spec 009 au statut « brouillon » : ligne « Design » dans le modèle de spec, question posée par `/spec` (charte et maquette, maquette, ou sans objet), nouvelle skill `/maquette`, contrôle par `/implement` avant `test-writer`, consignes au `reviewer`. 13 critères d'acceptation.
- Méthode reprise de Tidemark (artefact « Design System » pour la charte, artefact « Design » par spec, copie dans `docs/maquettes/` qui fait foi), avec ses limites constatées : pas de captures PNG, liens d'artefacts privés.

### Décisions

- Artefact Claude pour itérer, copie versionnée dans `docs/maquettes/` qui fait foi (Yanis).
- Spec séparée de la 008, PR indépendante basée sur `main` (Yanis).
- Spec validée sans ligne « Design » acceptée par `/implement`, qui pose la question une fois, pour ne pas casser FieldOps et Tidemark (agent, à valider par Yanis).
- Repli sans artefact : HTML produit directement dans le dépôt (agent, à valider par Yanis).

### Corrections et limites

- Les CA4 à CA13 ne se testent qu'à la main, sur un projet jetable.
- La spec mentionne `docs/plan.md` de la spec 008, encore en brouillon (PR #44) : la phrase est conditionnelle (« si `docs/plan.md` existe »).

### Prochaine étape

Yanis relit la spec 009 et répond aux trois questions ouvertes. L'implémentation suit celle de la spec 008.
