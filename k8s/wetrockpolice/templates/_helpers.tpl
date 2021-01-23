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
Common sidekiq labels
*/}}
{{- define "wetrockpolice.sidekiq.labels" -}}
helm.sh/chart: {{ include "wetrockpolice.chart" . }}
{{ include "wetrockpolice.sidekiq.selectorLabels" . }}
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
Sidekiq Selector labels
*/}}
{{- define "wetrockpolice.sidekiq.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wetrockpolice.name" . }}
app.kubernetes.io/instance: sidekiq
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
