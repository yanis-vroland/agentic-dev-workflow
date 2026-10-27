# Journal : <sujet de la branche>

Branche `<nom-de-la-branche>`.

<!--
Un fichier par branche : docs/journal/AAAA-MM-JJ-<branche>.md, les « / » remplacés
par des « - », date de création. Créé au premier commit de la branche, complété à
chaque commit de travail dans le même commit, puis poussé.

Ne jamais modifier le journal d'une autre branche ni un fichier déjà mergé : la
CI le refuse (verifier-journal.sh).
-->

## AAAA-MM-JJ HH:MM

### Fait

<!--
Ce qui a été fait, assez précisément pour qu'une autre session reprenne sans
contexte. Chiffres et noms de fichiers plutôt que généralités.

Une trace de contrôle ne cite jamais ce qu'elle cherche (CLAUDE.md, « Noms
exclus ») :
- à ne pas écrire : « recherche de Zorglub, Quibbler et Vantablex : 0 occurrence » ;
- à écrire : « recherche des noms de `EXCLUDED_NAMES` : 0 occurrence ».
-->

- …

### Décisions

<!-- Chaque décision avec qui l'a prise : l'humain, ou l'agent par délégation.
     « Aucune » si rien n'a été tranché. -->

- …

### Corrections et limites

<!-- Ce qui a été corrigé après coup, ce qui reste approximatif, ce qui a été
     tenté sans succès. Tout test modifié après son écriture est signalé ici. -->

- …

### Prochaine étape

<!-- Ce que la session suivante doit faire en premier. Le hook de début de
     session affiche cette rubrique : elle est le point de reprise. -->

- …
