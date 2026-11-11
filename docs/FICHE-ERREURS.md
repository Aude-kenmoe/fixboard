# FixBoard : erreurs fréquentes et solutions

Erreurs rencontrées en faisant le projet de bout en bout (Phases 1 et 2), avec leur cause et la correction.

---

## Avant de commencer

### `no configuration file provided: not found`
- **Quand :** `docker compose up --build`
- **Cause :** la commande est lancée en dehors du dossier du projet (le terminal affiche `~$`).
- **Solution :** `cd ~/fixboard`, puis relancer. Le terminal doit afficher `~/fixboard$`.

### Le port 5432 est déjà utilisé
- **Quand :** `docker compose up`, si PostgreSQL est déjà installé sur l'ordinateur.
- **Solution :** `POSTGRES_PORT=5433 docker compose up --build`

### Le fichier image va dans le mauvais champ
- Dans **New Post**, l'image va dans **Architecture image**, pas dans **Log file** (réservé aux fichiers texte).

---

## Phase 1 : Terraform et AWS

### `You must be logged in to the server (the server has asked for the client to provide credentials)`
- **Quand :** `kubectl get nodes` après `aws eks update-kubeconfig`.
- **Cause :** l'utilisateur AWS n'a pas accès à ce cluster (cluster créé par quelqu'un d'autre).
- **Solution :** se connecter à **son propre** cluster, ou demander au formateur de donner l'accès.
- **Vérifier quel cluster est utilisé :** `kubectl config current-context`

### Compte AWS partagé : conflits de noms
- **Cause :** si plusieurs personnes lancent Terraform avec les noms par défaut (`fixboard`, `ridgeline-fixboard`), les ressources portent les mêmes noms.
- **Solution :** dans `terraform/platform/terraform.tfvars`, utiliser des noms uniques :
  ```hcl
  project_name     = "prenom-fixboard"
  cluster_name     = "prenom-fixboard"
  argocd_hostname  = "argocd-prenom.mondomaine.com"
  grafana_hostname = "grafana-prenom.mondomaine.com"
  ```
  Puis adapter les clés dans `k8s/02-externalsecrets.yaml` : `prenom-fixboard/db-credentials` et `prenom-fixboard/backend-secrets`.

### `could not download chart … aws.github.io … context deadline exceeded`
- **Quand :** `terraform apply` (installation des composants Helm).
- **Cause :** le réseau (école, entreprise, opérateur) bloque les sites `*.github.io`.
- **Test :** `curl -I https://aws.github.io/eks-charts/index.yaml` → si ça ne répond pas, c'est bloqué.
- **Solution 1 :** utiliser le partage de connexion du téléphone.
- **Solution 2 :** télécharger les charts depuis `github.com`, qui n'est pas bloqué. Dans `modules/addons/main.tf` et `modules/gitops/main.tf`, remplacer `repository` + `chart` + `version` par une adresse directe :
  ```hcl
  chart = "https://raw.githubusercontent.com/aws/eks-charts/gh-pages/aws-load-balancer-controller-3.6.2.tgz"
  chart = "https://github.com/kubernetes-sigs/external-dns/releases/download/external-dns-helm-chart-1.23.0/external-dns-1.23.0.tgz"
  chart = "https://github.com/external-secrets/external-secrets/releases/download/helm-chart-2.14.0/external-secrets-2.14.0.tgz"
  chart = "https://github.com/argoproj/argo-helm/releases/download/argo-cd-10.17.1/argo-cd-10.17.1.tgz"
  ```
- Après une erreur, relancer avec `terraform apply` (**sans** `tfplan`) : Terraform reprend là où il s'est arrêté.

### Le fichier `tfplan` risque d'être envoyé sur GitHub
- **Cause :** `.gitignore` ignore `*.tfplan`, mais le guide nomme le fichier `tfplan` (sans extension). Ce fichier peut contenir des mots de passe.
- **Solution :** ajouter `tfplan` dans `terraform/.gitignore`.

### Le compte AWS a déjà un fournisseur OIDC GitHub
- **Solution :** `create_github_oidc_provider = false` dans `terraform.tfvars`.

---

## Phase 1 : images Docker

### `":1.1.0" is not a valid repository/tag: invalid reference format`
- **Cause :** la variable `$ECR_FRONTEND` (ou `$ECR_BACKEND`) est vide, parce qu'on a ouvert un **nouveau terminal**.
- **Solution :** retaper les `export …`, puis vérifier avec `echo $ECR_FRONTEND`.

### `docker push` : `net/http: timeout awaiting response headers`
- **Cause :** connexion internet lente.
- **Solution :** relancer la même commande `docker push`. Les morceaux déjà envoyés sont gardés.

### `no basic auth credentials`
- **Cause :** la connexion à ECR a expiré (12 heures).
- **Solution :** refaire `aws ecr get-login-password … | docker login …`

---

## Phase 1 : Kubernetes

### Le site ne s'ouvre pas tout de suite après `kubectl apply -f k8s/07-ingress.yaml`
- **Normal :** AWS met 3 à 5 minutes à créer le load balancer, puis le nom DNS met quelques minutes à être connu.
- **Suivre :** `kubectl get ingress -w` (attendre l'adresse dans **ADDRESS**).

### HPA : `cpu: <unknown>/50%`
- **Normal** pendant la première minute. Relancer `kubectl get hpa backend`.

### `ImagePullBackOff` / `ErrImagePull`
- **Cause :** l'image ou sa version n'existe pas sur ECR (faute de frappe, ou `docker push` oublié).

### `kubectl rollout undo` lancé deux fois
- `undo` revient à la version **juste avant**. Le lancer deux fois fait un aller-retour (on retombe sur la version cassée).
- **Meilleure méthode :** corriger la version dans le fichier, puis `kubectl apply -f k8s/06-frontend.yaml`.

---

## Phase 2 : pipeline GitHub Actions

### Je ne trouve pas « New repository secret »
- Dans **Settings → Secrets and variables → Actions**, aller dans l'onglet **Secrets** (pas **Variables**).
- **Ou en ligne de commande :** `gh secret set NOM_DU_SECRET -R utilisateur/fixboard` (coller avec Ctrl + Shift + V).

### `build` échoue à **Scan backend** (Trivy : dizaines de failles HIGH/CRITICAL)
- **Cause :** de nouvelles failles ont été découvertes depuis l'écriture du cours.
- **Solution :**
  1. Dans `backend/Dockerfile`, installer les mises à jour système et retirer npm de l'image finale :
     ```dockerfile
     FROM node:20-slim
     RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
     WORKDIR /app
     COPY package*.json ./
     RUN npm ci --omit=dev \
      && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx
     ```
  2. Mettre à jour les bibliothèques (dans `backend/`) :
     ```bash
     npm install --package-lock-only --ignore-scripts multer@^2.3.0 bcrypt@^6.0.0
     npm update --package-lock-only --ignore-scripts
     npm audit --package-lock-only --omit=dev   # doit afficher 0 vulnerabilities
     ```

### `build` échoue à **Scan frontend** (`libxslt`)
- **Solution :** dans `frontend/Dockerfile`, juste après `FROM nginx:alpine` :
  ```dockerfile
  RUN apk upgrade --no-cache
  ```

### `verify` échoue : `permission denied: projects, get, default, sub: ci`
- **Cause :** les versions récentes d'ArgoCD demandent aussi le droit de lire le **projet**.
- **Solution :** dans `terraform/platform/modules/gitops/main.tf`, ajouter dans `policy.csv` :
  ```
  "p, role:ci, projects, get, default, allow",
  ```
  Puis `terraform apply` et relancer le job **verify** (Actions → Re-run failed jobs).

### `verify` échoue : `lookup argocd-… no such host`
- **Cause :** le load balancer d'ArgoCD n'existe plus (supprimé à la main) ou le DNS n'est pas encore à jour.
- **Vérifier :** `kubectl get ingress -n argocd` et la console AWS **EC2 → Load Balancers**.

### Appliquer l'application ArgoCD **avant** de fusionner la pull request
- `kubectl apply -f argocd/application.yaml` avant le premier merge. Sinon `verify` ne trouve pas l'application `fixboard`.

### `gh run rerun --failed` : `unknown flag`
- Ancienne version de `gh`. Utiliser le bouton **Re-run failed jobs** sur GitHub.

---

## Nettoyage

### Ordre à respecter
1. Supprimer l'application dans ArgoCD (ou `kubectl delete -f k8s/`) pour que les load balancers soient supprimés.
2. Vérifier dans **EC2 → Load Balancers** qu'ils ont disparu.
3. `terraform destroy`

### `terraform destroy` bloque, ou le VPC ne se supprime pas
- **Cause :** des groupes de sécurité `k8s-…` créés par Kubernetes restent dans AWS.
- **Solution :** les supprimer dans **EC2 → Security Groups** (filtrer sur `k8s-`), puis relancer `terraform destroy`.
