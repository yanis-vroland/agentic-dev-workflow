# Journal : implémentation de la spec 009, design system et maquette

Branche `feat/spec-009-maquette`.

## 2026-10-14 20:40

### Fait

- Spec 009 alignée sur la spec 008 mergée : la question « Design » suit l'étape 8 de `/spec` (une étape ajoutée par la spec 008) ; cas limite des données réelles restreint aux données personnelles, les noms du client et du produit étant admis (décision du 2026-10-14 sur les projets clients).
- Tests rouges écrits par le subagent `test-writer` (lancé comme subagent générique avec ses consignes et son modèle `sonnet`) : deux étapes de `template-ci.yml` (CA1, ligne « Design » et section « Maquette » du modèle de spec ; CA2, skill `maquette` invocable par l'agent), un cas dans `tests/init-script.sh` (CA2, skill copiée). Aucune vérification existante modifiée (CA3).
- Résultat : `init-script.sh` 284 OK et 3 ÉCHEC, tous sur la spec 009 CA2 (skill absente) ; étapes CI CA1 et CA2 en échec sur le dépôt actuel, vertes sur une copie conforme, et contrôlées par mutation par le subagent.

### Décisions

- Corrections de la spec sans nouveau critère : alignement sur des décisions déjà prises par Yanis (agent).

### Corrections et limites

- Les CA4 à CA14 ne se testent qu'en session, sur un projet jetable.

### Prochaine étape

Accord de Yanis sur les tests rouges, puis implémentation : modèle de spec, skill `maquette`, `/spec`, `/implement`, `reviewer`, README.
