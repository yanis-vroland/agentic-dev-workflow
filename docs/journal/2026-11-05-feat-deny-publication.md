# Journal : interdictions de publication dans les permissions (spec 010)

Branche `feat/deny-publication`.

## 2026-11-05 20:41

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

## 2026-11-05 20:43

### Fait

- `.claude/settings.json` : trois `deny` ajoutés. Spec 010 : cas limite « Permissions ». Les trois vérifications passent ; `tests/hooks.sh` et `tests/init-script.sh` au vert, JSON valide.

### Décisions

- Aucune nouvelle.

### Corrections et limites

- Test humain sans objet : la règle s'applique au prochain démarrage de Claude Code, et la vérifier exigerait de tenter l'action interdite.

### Prochaine étape

- PR, revue IA, merge par Yanis.

## 2026-11-05 20:48

### Fait

- Revue IA de la PR #61 : rien de bloquant. Corrigé : la spec 010 ne prête plus à Yanis l'ajout de `Edit(./.excluded-names)`, marqué « proposé par l'agent, à valider par Yanis au merge » ; le test vérifie les règles dans `permissions.deny` par `jq`, et non n'importe où dans le fichier (mutation : la règle déplacée dans `allow` fait échouer le test) ; limite du contournement par `gh api` consignée dans la spec.
- Heures des deux entrées précédentes recalées sur celles des commits (écrites à l'avance).

### Décisions

- Agent : pas de règle `deny` sur `gh api`, un motif de ce genre restant contournable ; limite documentée à la place.

### Corrections et limites

- Le test humain « sans objet » était à tort : le comportement de l'agent change. Test humain demandé à Yanis dans une nouvelle session.

### Prochaine étape

- Test humain de Yanis et validation de `Edit`, réponse à la revue IA, merge.
