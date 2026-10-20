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

## 2026-10-20 13:15

### Fait

- Revues `reviewer` et `security-reviewer` avant la PR. Six points bloquants au total, tous corrigés et couverts par un test.
- **Faux négatif silencieux** (sécurité, bloquant) : `grep -q` alimenté par un tuyau sortait à la première correspondance, tuait le producteur par SIGPIPE, et `pipefail` transformait la trouvaille en absence. Reproduit : un diff de 5,7 Mo avec le nom en première ligne passait inaperçu. Toutes les comparaisons passent désormais par un fichier (`matches_text`), et un test couvre le cas.
- **Fichier `.excluded-names` suivi, en CI sans secret** (revue, bloquant) : le contrôle arrivait après la sortie anticipée « aucune liste », donc le cas le plus grave passait au vert. Le contrôle précède maintenant tout chargement de liste et sort en 1, quelle que soit la liste.
- **`fetch-depth: 0`** sur le job `garde-fous` : sans l'historique complet, `origin/main` n'existe pas sur un événement `pull_request` et le contrôle sortait en erreur à chaque PR.
- **Interpolation `${{ }}` dans un `run:`** : `github.base_ref` passe par `env:`, comme les autres variables de PR.
- **Commits de fusion et renommages** : `--diff-merges=first-parent` et contrôle des chemins touchés ; sans eux, un nom introduit en résolvant un conflit, ou un renommage défait plus loin, ne laissait aucune trace.
- **Plage recopiée** : une branche nommée d'après un nom exclu fuitait dans la sortie, en succès comme en erreur ; la plage est masquée si elle contient un nom.
- **Deux tests qui passaient à vide** : le nom trop court (le dépôt contenait le nom court, et le test acceptait 1 ou 2) et la protection `in_ci`, jamais exercée. Corrigés, mutation vérifiée pour les deux.
- **`.gitignore` du template** : il ne protégeait pas son propre `.excluded-names`, alors que `init.sh` l'ajoute aux projets dérivés.
- **`init.sh` armait le garde-fou sans le dire** : une étape explique désormais comment créer le secret et le fichier local, sans quoi la CI reste verte sans rien vérifier.
- README (documentation de référence de ce dépôt) : script et modèle de journal listés, `garde-fous.yml` redécrit, spec 010 dans le tableau des specs et dans la liste `git rm` d'adoption.
- Résultats : 74 vérifications du garde-fou, 307 de `init-script.sh`, shellcheck sans avertissement.

### Décisions

- Aucune nouvelle. CA15 élargi (« quelle que soit la liste, en CI comme en local ») pour coller à la section « Le script » : c'est son rétrécissement qui avait laissé passer le trou.

### Corrections et limites

- Limites ajoutées à la spec : PR venue d'un fork (GitHub ne transmet pas les secrets, le garde-fou se saute), locale UTF-8 absente sous macOS, nom contenant une virgule.
- Non suivi : épingler `actions/checkout` par SHA (défaut préexistant à cette PR, à traiter séparément) ; `docs/templates/journal.md` redit trois règles du `CLAUDE.md` (gardées sur place, un modèle doit se lire seul).
- **Test humain à faire par Yanis** : lancer `scripts/verifier-noms-exclus.sh` sur un dépôt réel et vérifier les deux étapes de CI sur cette PR. La revue note à juste titre qu'un test humain aurait révélé le défaut de `fetch-depth`.

### Prochaine étape

- PR, revue IA et réponse ; puis seconde PR pour `verifier-avant-public.sh` et `/publier` (CA9 à CA11).
