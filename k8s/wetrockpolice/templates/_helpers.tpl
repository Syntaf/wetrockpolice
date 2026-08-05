{{/*
Expand the name of the chart.
*/}}
{{- define "wetrockpolice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wetrockpolice.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wetrockpolice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wetrockpolice.labels" -}}
helm.sh/chart: {{ include "wetrockpolice.chart" . }}
{{ include "wetrockpolice.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wetrockpolice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wetrockpolice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Postgres object name. Matches the name the Bitnami subchart produced, because
the app deployment reaches the database at this Service name and reads its
password from the Secret of the same name (key `postgres-password`).
*/}}
{{- define "wetrockpolice.postgresql.fullname" -}}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}

{{/*
StatefulSet name. Deliberately NOT the Bitnami-era `<release>-postgresql`:
a StatefulSet's selector and volumeClaimTemplates are immutable, and both
differ from what the Bitnami subchart deployed, so reusing that name would
make the cutover `helm upgrade` try an in-place patch the API server
rejects (`spec: Forbidden`), failing the release mid-rollout. A fresh name
turns the cutover into delete-old/create-new: Helm removes the Bitnami
StatefulSet (its manifest left the chart) and creates this one, whose pod
binds a brand-new PVC instead of silently inheriting the PG 15 volume
(`data-<release>-postgresql-0`), which is left behind for manual backup or
cleanup. Only Services and the Secret keep the old name — those are what
the app points at, and they are mutable.
*/}}
{{- define "wetrockpolice.postgresql.statefulsetName" -}}
{{- printf "%s-postgres" .Release.Name }}
{{- end }}

{{/*
Postgres selector labels. Deliberately a different `name` label than the app's
selectorLabels: label selectors match on subsets, so sharing the app's
name+instance pair would put the postgres pod behind the app's Service.
*/}}
{{- define "wetrockpolice.postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wetrockpolice.name" . }}-postgresql
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Postgres common labels
*/}}
{{- define "wetrockpolice.postgresql.labels" -}}
helm.sh/chart: {{ include "wetrockpolice.chart" . }}
{{ include "wetrockpolice.postgresql.selectorLabels" . }}
app.kubernetes.io/component: postgresql
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wetrockpolice.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wetrockpolice.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
