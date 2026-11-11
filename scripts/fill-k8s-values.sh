#!/usr/bin/env bash
# Replaces the placeholders in k8s/*.yaml with the values from Terraform.
# Usage (from the repository root, after `terraform apply` in terraform/platform):
#   ./scripts/fill-k8s-values.sh fixboard.yourdomain.com
set -euo pipefail

APP_HOST="${1:?Give your FixBoard host name, for example fixboard.yourdomain.com}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT/terraform/platform"
ECR_BACKEND=$(terraform output -json ecr_repository_urls | jq -r .backend)
ECR_FRONTEND=$(terraform output -json ecr_repository_urls | jq -r .frontend)
RDS_HOST=$(terraform output -raw rds_endpoint | cut -d: -f1)   # host only, no port
CERT_ARN=$(terraform output -raw certificate_arn)

cd "$ROOT"
sed -i \
  -e "s|<ECR_BACKEND>|$ECR_BACKEND|g" \
  -e "s|<ECR_FRONTEND>|$ECR_FRONTEND|g" \
  -e "s|<RDS_HOST>|$RDS_HOST|g" \
  -e "s|<CERT_ARN>|$CERT_ARN|g" \
  -e "s|fixboard\.example\.com|$APP_HOST|g" \
  k8s/*.yaml

echo "Values filled in. Anything still listed below needs fixing by hand:"
grep -nE "<[A-Z_]+>|example\.com" k8s/*.yaml || echo "  (nothing left, ready to apply)"
