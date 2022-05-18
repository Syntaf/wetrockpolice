GRAFANA_POD=$(kubectl -n loki get pods -l app=grafana -o jsonpath="{.items[0].metadata.name}")
PASSWORD=$(kubectl get secret --namespace loki loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "password: ${PASSWORD}"

kubectl --namespace loki port-forward $GRAFANA_POD 3000