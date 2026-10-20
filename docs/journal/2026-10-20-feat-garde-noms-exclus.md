# Journal : garde-fou des noms exclus, spec 010

Branche `feat/garde-noms-exclus`.

## 2026-10-20 09:30

### Fait

- Spec 010 rédigée au statut brouillon, à partir de trois frictions constatées sur Tidemark les 2026-10-16 et 2026-10-20 : le garde-fou arrivé au quatrième jour sur 36 PR déjà mergées ; la fuite venue d'une trace de contrôle qui citait les noms cherchés ; le dépôt passé en public alors que la réécriture de l'historique était inscrite comme préalable depuis quatre jours.
- Périmètre proposé : le script et ses tests dans le socle copié par `init.sh`, un contrôle avant publication, la règle de rédaction des traces de contrôle, et le contrôle par mutation.
- Aucun test ni code écrit : la spec attend la validation de Yanis (méthode de travail, règle 1).

### Décisions

- Aucune. Deux questions ouvertes laissées à Yanis : découper ou non la PR, et rétroporter ou non dans Tidemark et FieldOps.

### Corrections et limites

- Le contrôle avant publication ne peut pas empêcher `gh repo edit --visibility public` : il constate, l'humain décide (ADR-002). C'est une limite assumée, écrite dans la spec.
- `docs/learnings/` est vide : aucun piège relu pour cette spec.

### Prochaine étape

- Validation de la spec par Yanis, puis tests par le subagent `test-writer`, puis implémentation.

## 2026-10-20 09:45

### Fait

- Spec 010 passée à « validée » ; questions ouvertes tranchées.

### Décisions

- Spec 010 validée par Yanis (2026-10-20).
- Découpage en deux PR, recommandation de l'agent retenue par Yanis : script, tests, socle et règle de rédaction d'abord ; contrôle avant publication ensuite.
- Rétroportage dans Tidemark et FieldOps reporté après la seconde PR (agent, à confirmer par Yanis le moment venu).

### Corrections et limites

- Aucune.

### Prochaine étape

- Tests de la première PR (CA1 à CA8, CA12 à CA14) par le subagent `test-writer`, rouges avant implémentation.

## 2026-10-20 11:30

### Fait

- Tests écrits par le subagent `test-writer`, committés rouges (d98e815) : `tests/verifier-noms-exclus.sh` (59 vérifications), compléments de `tests/init-script.sh` (CA1, CA2) et deux étapes de `template-ci.yml` (CA12, CA13).
- Implémentation (cf891dd) : `scripts/verifier-noms-exclus.sh` porté depuis le projet d'origine ; copie par `init.sh` et ligne `/.excluded-names` du `.gitignore` ; deux étapes dans `garde-fous.yml` (test du garde-fou, et contrôle de la plage de la PR avec le secret) ; section « Noms exclus » du `CLAUDE.md` avec la règle des traces de contrôle ; `docs/templates/journal.md` créé, qui rappelle la règle dans sa rubrique « Fait ».
- Résultats : 59 vérifications du garde-fou au vert, 302 de `init-script.sh`, shellcheck sans avertissement, étapes CA12 et CA13 vérifiées en local.
- Contrôle par mutation des six protections du script : contenu d'un fichier suivi (10 échecs), chemin (2), message de commit (4), auteur et committer (8), lignes ajoutées (6), fichier `.excluded-names` suivi (2 après ajout du test).

### Décisions

- Liste absente : avertissement et succès, en CI comme en local (Yanis, 2026-10-20). Le projet d'origine échouait en CI. Limite assumée, écrite dans la spec : un secret supprimé par erreur laisse la CI verte.

### Corrections et limites

- CA15 ajouté à la spec pendant l'implémentation : le contrôle par mutation a montré qu'aucun test ne couvrait le refus d'un fichier `.excluded-names` suivi par Git. Test écrit, mutation vérifiée. **À valider par Yanis au merge.**
- Trois premières tentatives de mutation sans effet (expressions `sed` qui ne correspondaient à rien) : refaites avec un script Python qui échoue si le motif est absent. Sans cela, j'aurais conclu à tort que les tests étaient aveugles.
- `tests/verifier-noms-exclus.sh` n'était pas exécutable à sa création : corrigé, le CA1 le vérifie.

### Prochaine étape

- Revues `reviewer` et `security-reviewer`, puis PR ; seconde PR ensuite pour `verifier-avant-public.sh` et `/publier` (CA9 à CA11).
