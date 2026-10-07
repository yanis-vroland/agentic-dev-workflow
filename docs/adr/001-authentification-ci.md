# ADR-001 : Authentification de la CI auprès de Claude

Statut : accepté

Contexte : la revue de PR par IA tourne sur GitHub Actions, qui doit s'authentifier
auprès de Claude. Projet personnel, budget à maîtriser.

Options envisagées :
- Clé API : coût mesurable au token, mais facture variable à surveiller.
- Token d'abonnement : pas de surcoût, mais consomme les limites de l'abonnement
  et ne permet pas de mesurer un coût réel.

Décision : token d'abonnement pour la revue de code de P1. Une clé API sera utilisée
pour P3 et P4, où le coût par requête est une métrique à démontrer.

Conséquences : pas de chiffre de coût pour la revue IA ; si les limites
d'abonnement deviennent bloquantes, bascule vers une clé API avec plafond.