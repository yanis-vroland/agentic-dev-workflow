# Spec 010 : garde-fou des noms exclus

Statut : validée (Yanis, 2026-10-20)
Date : 2026-10-20

## Besoin

En tant que développeur dont les dépôts de démonstration finissent publics, je veux que la chaîne refuse dès le premier commit tout nom de client ou d'employeur réel, afin de ne pas découvrir une fuite le jour de la publication, quand l'historique est déjà écrit.

Constats d'origine (2026-10-16 et 2026-10-20, projet Tidemark, construit avec la chaîne) :

- Le garde-fou n'existe que dans Tidemark, où il est arrivé **au quatrième jour** (sa PR #42), alors que 36 PR étaient déjà mergées. Il a trouvé une occurrence dans un commit déjà sur `main`, impossible à corriger sans réécrire l'historique.
- La fuite venait d'une **trace de contrôle** : une entrée de journal consignait « recherche de A, B et C : 0 occurrence », en citant les trois noms cherchés. Le contrôle s'est dénoncé lui-même.
- Le dépôt est passé en public avec cet historique, alors que la réécriture était inscrite comme préalable depuis quatre jours. Un préalable écrit dans un plan n'empêche rien.
- La réécriture a dû se faire sur un clone **miroir** : un clone simple ne couvrait que 21 des 41 branches. Et `refs/pull/*` reste hors d'atteinte, ce qui laisse les anciens commits accessibles par leur identifiant.

Le template n'a ni cahier des charges ni architecture technique propres (spec 003, « Hors périmètre »). `docs/learnings/` est vide : aucun piège n'a été relu pour cette spec.

## Principes

1. **Dès le premier commit.** Le garde-fou fait partie du socle copié par `init.sh`, comme les hooks de qualité. Un projet ne doit jamais avoir à l'ajouter après coup.
2. **Jamais le nom en clair.** Le script ne l'affiche pas, ne l'écrit pas dans un message d'erreur, et n'en met aucun dans le dépôt. La liste vit dans le secret `EXCLUDED_NAMES` en CI, ou dans `.excluded-names` en local, non versionné.
3. **Une trace de contrôle ne cite pas ce qu'elle cherche.** C'est la règle qui manquait. Écrire « recherche des noms de `EXCLUDED_NAMES` : 0 occurrence », jamais la liste.
4. **Le préalable à la publication est technique, pas documentaire.** Une commande vérifie tout l'historique et dit si le dépôt peut devenir public ; elle ne repose pas sur une case à cocher.

## Le script

`scripts/verifier-noms-exclus.sh [plage | --all]`, repris de Tidemark, où il tourne depuis sa PR #42.

- Lit la liste dans `EXCLUDED_NAMES` (une par ligne) ou, à défaut, dans `.excluded-names`. Sans liste : avertissement et sortie en succès, pour ne pas bloquer un projet qui n'en a pas besoin.
- Cherche sans tenir compte de la casse, par sous-chaîne : contenu et chemin des fichiers suivis ; pour chaque commit de la plage, message, auteur, committer et lignes ajoutées ; titre, description et nom de branche de la PR.
- `--all` relit tout l'historique, toutes références comprises.
- N'affiche jamais le nom trouvé : seulement l'identifiant du commit ou le chemin du fichier.

## Critères d'acceptation

### Socle copié par `init.sh`

- CA1 : Étant donné un projet initialisé par `scripts/init.sh`, alors `scripts/verifier-noms-exclus.sh` et `tests/verifier-noms-exclus.sh` sont présents, exécutables, et l'étape correspondante figure dans `garde-fous.yml`.
- CA2 : Étant donné ce projet, alors `.gitignore` contient `/.excluded-names`.
- CA3 : Étant donné un dépôt sans liste (ni `EXCLUDED_NAMES` ni `.excluded-names`), quand le script tourne, alors il avertit qu'aucune liste n'est définie et sort en succès.

### Le script

- CA4 : Étant donné une liste et un fichier suivi qui contient un nom, quand le script tourne, alors il échoue et nomme le fichier, **sans jamais afficher le nom**.
- CA5 : Idem pour un nom dans le chemin d'un fichier suivi, dans le message d'un commit de la plage, dans son auteur ou son committer, et dans les lignes qu'il ajoute.
- CA6 : Étant donné un commit qui **retire** un nom, quand le script tourne sur sa plage, alors il réussit.
- CA7 : Étant donné `--all`, quand le script tourne, alors il relit tout l'historique, y compris les branches non fusionnées.
- CA8 : Étant donné une sortie en échec, alors aucun nom de la liste n'apparaît dans la sortie standard ni dans la sortie d'erreur.

### Contrôle avant publication

- CA9 : `scripts/verifier-avant-public.sh` sort en échec si `verifier-noms-exclus.sh --all` échoue, si des `refs/pull/*` atteignent un commit refusé, ou si un fichier `.env` est suivi ; il sort en succès sinon, et dit dans les deux cas ce qu'il a vérifié.
- CA10 : Étant donné un dépôt dont l'historique est propre mais dont des références de PR exposent un ancien commit, alors le script le signale, nomme les PR concernées et renvoie à la marche à suivre.
- CA11 : La skill `/publier` lance `verifier-avant-public.sh` et **refuse de proposer la mise en public** tant qu'il échoue ; elle ne lance jamais elle-même `gh repo edit --visibility public`, qui reste une action de l'humain.

### Règle de rédaction

- CA12 : `CLAUDE.md` du template contient la règle « une trace de contrôle ne cite jamais ce qu'elle cherche », avec l'exemple à ne pas suivre et sa formulation correcte.
- CA13 : `docs/templates/journal.md` rappelle cette règle dans la rubrique « Fait ».

### Contrôle par mutation

- CA14 : Chaque protection du script est désactivée une fois et au moins un test de `tests/verifier-noms-exclus.sh` échoue (méthode de travail, règle 2).

## Cas limites et erreurs

- Nom coupé par un retour à la ligne, écrit avec des caractères qui se ressemblent, ou sous une autre forme Unicode : non détecté, limite assumée et documentée.
- Fichier en UTF-16 ou compressé (PNG, PDF, zip) : les lignes ajoutées ne sont lues que dans l'arbre final.
- Liste vide ou ne contenant que des lignes blanches : traitée comme une absence de liste (CA3).
- Nom d'un seul caractère ou très court : refusé par le script, qui exige au moins 3 caractères, pour éviter un faux positif permanent.

## Hors périmètre

- Réécrire l'historique à la place de l'humain : le script constate, il ne corrige pas.
- Détecter autre chose qu'une liste de noms fournie (secrets, adresses) : c'est le rôle de `gitleaks`, déjà dans `garde-fous.yml`.
- Empêcher techniquement `gh repo edit --visibility public` : impossible, et la mise en public reste une décision humaine (ADR-002).

## Questions ouvertes

Aucune.

1. **Périmètre** tranché le 2026-10-20 : deux PR. La première livre le script, ses tests, le socle et la règle de rédaction (CA1 à CA8, CA12 à CA14) ; la seconde `verifier-avant-public.sh` et `/publier` (CA9 à CA11). Recommandation de l'agent, retenue par Yanis : deux PR plus courtes à relire, et la première apporte déjà l'essentiel.
2. **Rétroportage** dans Tidemark et FieldOps : à décider par Yanis après la livraison de la seconde PR.
