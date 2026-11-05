# Sous `pipefail`, ne jamais terminer un tuyau par `grep -q` : le SIGPIPE fait échouer la trouvaille

Domaine : transverse (scripts shell, garde-fous de sécurité)
Statut : actif
Date : 2026-11-05

## Symptôme

Sous macOS, `scripts/verifier-noms-exclus.sh` affichait à chaque lancement « Avertissement : aucune locale UTF-8 disponible », alors que `locale -a` listait `en_US.UTF-8` et `fr_FR.UTF-8`. Conséquence silencieuse : la comparaison retombait sur la locale C, et un nom accentué écrit dans une autre casse (É/é) n'était plus détecté par un garde-fou de sécurité.

## Cause racine

`locale -a 2>/dev/null | grep -qix …` dans un script en `set -o pipefail`. `grep -q` sort à la première correspondance, le producteur (`locale -a`) reçoit SIGPIPE en écrivant la suite, et `pipefail` transforme la trouvaille en échec du tuyau. Reproduit 20 fois sur 20.

C'est la deuxième occurrence du même mécanisme dans ce script : la PR #58 l'avait corrigé pour les comparaisons de noms (un diff de 5,7 Mo avec le nom en première ligne passait inaperçu), pas pour la détection de locale. Les tests passaient parce qu'aucun ne vérifiait l'absence de l'avertissement ni le repli de casse des accents : le mode dégradé ne produisait aucun échec visible.

## Règle pour la prochaine fois

- Dans un script en `set -o pipefail`, ne jamais terminer un tuyau par `grep -q`, `head`, ni aucune commande qui sort avant la fin de l'entrée. Lire la sortie une fois dans une variable (`locales=$(locale -a 2>/dev/null)`), puis `grep -q … <<<"$locales"`, ou passer par un fichier.
- Avant de livrer un script, chercher tous les tuyaux `| grep -q` / `| head` du fichier, pas seulement celui qui vient d'échouer.
- Quand un garde-fou a un repli « dégradé » (ici la locale C), tester l'effet observable du mode normal (pas d'avertissement, comparaison insensible à la casse sur les accents), pas seulement le code de sortie.
- Protection durable : cas limite « Locale » de `tests/verifier-noms-exclus.sh`.

## Où

- `scripts/verifier-noms-exclus.sh` (détection de locale, comparaison de noms).
- Tout script du dépôt avec `set -o pipefail` et un tuyau terminé par `grep -q` ou `head` (hooks de `.claude/`, scripts de CI).

## Vu sur

- Spec 010, PR #58 (comparaisons de noms), branche antérieure.
- Spec 010, branche `feat/verifier-avant-public`, correctif `4042861` (test de non-régression `4042861^`).
