# Journal : interdictions de publication dans les permissions (spec 010)

Branche `feat/deny-publication`.

## 2026-11-05 20:50

### Fait

- PR #60 mergée par Yanis ; contenu de `main` (`29c046d`) identique au dernier commit de la PR (`971091e`).
- Branche créée pour la suite décidée par Yanis : interdire à l'agent, par les `deny` de `.claude/settings.json`, de lire ou modifier `.excluded-names` et de lancer `gh repo edit`.
- Tests rouges committés avant la modification : trois vérifications dans `tests/verifier-avant-public.sh`.

### Décisions

- Yanis : `deny` dans une PR séparée de #60.
- Agent : `Edit(./.excluded-names)` ajouté en plus de `Read`, pour que « seul l'humain crée ou modifie la liste » (spec 010, ajouts validés) soit aussi une garantie technique.

### Corrections et limites

- `Read` et `Edit` ne couvrent pas une lecture par `Bash` (`cat .excluded-names`) : la protection reste partielle, la skill garde sa consigne.

### Prochaine étape

- Modifier `.claude/settings.json`, puis PR.
