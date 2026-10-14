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

## 2026-10-14 16:17

### Fait

- Spec 009 mise à jour selon les réponses de Yanis : captures PNG obligatoires, rendues depuis l'artefact Claude, une par écran et par état, refaites à chaque modification ; `/maquette` lancée par l'agent après accord, sans commande à taper (cohérent avec la spec 008). 15 critères d'acceptation.

### Décisions

- Captures PNG obligatoires, par les artefacts Claude (Yanis).
- Sans artefact : arrêt et choix de l'humain, au lieu d'un repli silencieux en HTML ; une maquette sans capture n'est pas présentée comme complète (agent, à valider par Yanis).

### Corrections et limites

- Le moyen de produire une capture PNG depuis un artefact n'est pas vérifié (échec sur Tidemark) : spike à faire avant l'implémentation, consigné en question ouverte.

### Prochaine étape

Yanis relit la spec 009 et tranche les deux questions ouvertes restantes (place de la question « Design », contrôle des valeurs codées en dur par le `reviewer`). Spike des captures avant l'implémentation.

## 2026-10-14 16:21

### Fait

- Questions ouvertes de la spec 009 tranchées, sauf le moyen de capture.

### Décisions

- Question « Design » posée par `/spec` ; `reviewer` qui relève les valeurs visuelles codées en dur dès cette spec (Yanis, accord sur les propositions de l'agent).

### Corrections et limites

- Spec laissée au statut « brouillon » tant que le spike des captures n'a pas eu lieu.

### Prochaine étape

Spike des captures PNG depuis un artefact, puis validation de la spec 009 par Yanis. Implémentation après la spec 008.

## 2026-10-14 16:23

### Fait

- Spec 009 : captures PNG rendues facultatives ; plus de question ouverte, donc plus de spike prévu.

### Décisions

- Pas de capture automatique depuis l'artefact : PNG faits à la main par Yanis si besoin, ou pris dans l'application lancée en développement au test humain (Yanis).

### Corrections et limites

- Sans capture, un lecteur du dépôt ne voit la maquette qu'en ouvrant le HTML versionné : les liens d'artefacts restent privés.

### Prochaine étape

Validation de la spec 009 par Yanis. Implémentation après celle de la spec 008.

## 2026-10-14 16:24

### Fait

- Spec 009 passée au statut « validée ».

### Décisions

- Spec 009 validée (Yanis).

### Corrections et limites

- Aucune.

### Prochaine étape

Yanis merge cette PR (spec seule). L'implémentation de la spec 009 suit celle de la spec 008, sur une nouvelle branche basée sur `main` à jour.
