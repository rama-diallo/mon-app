# TP DevOps — Automatisation
UCAD — Département Informatique 2025-2026

## Partie 1 — Script bash
### Utilisation
```bash
chmod +x auto_deploy.sh
./auto_deploy.sh <URL_du_depot> [nom_dossier]
```

## Partie 2 — GitHub Actions
Pipeline CI/CD déclenché automatiquement à chaque push sur main.
Etapes : checkout, install Node.js 18, npm install, npm test, build.

## Partie 3 — Terraform
### Commandes
```bash
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy
```

### Questions de reflexion
**1. Avantages IaC vs manuel** : versioning, reproductibilite, moins d'erreurs humaines.
**2. Terraform dans CI/CD** : terraform plan sur PR, terraform apply apres merge sur main, credentials dans secrets GitHub.
**3. Precautions tfstate** : ne jamais committer .tfstate, utiliser un backend distant (S3+DynamoDB) en equipe.
