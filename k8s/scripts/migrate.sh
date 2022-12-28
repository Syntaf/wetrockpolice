crds=("certificaterequests.cert-manager.io" "certificates.cert-manager.io" "challenges.acme.cert-manager.io" "clusterissuers.cert-manager.io" "issuers.cert-manager.io" "orders.acme.cert-manager.io")

for crd in "${crds[@]}"; do
  manager_index="$(kubectl get crd "${crd}" --show-managed-fields --output json | jq -r '.metadata.managedFields | map(.manager == "cainjector") | index(true)')"
done