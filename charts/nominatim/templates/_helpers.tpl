{{/*
Expand the name of the chart.
*/}}
{{- define "nominatim.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nominatim.fullname" -}}
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
{{- define "nominatim.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nominatim.labels" -}}
helm.sh/chart: {{ include "nominatim.chart" . }}
{{ include "nominatim.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nominatim.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nominatim.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nominatim.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nominatim.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the pvc used for multiRegion updates
*/}}
{{- define "nominatim.updatePvcName" -}}
{{- printf "%s-update" (include "nominatim.fullname" .) -}}
{{- end }}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "nominatim.postgresql.fullname" -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "nominatim.database" -}}
{{- ternary (include "nominatim.postgresql.fullname" .) .Values.externalDatabase.host .Values.postgresql.enabled | quote -}}
{{- end -}}

{{- define "nominatim.databaseHost" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "%s" (include "nominatim.postgresql.fullname" .) -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
DB Host used for read only connections
*/}}
{{- define "nominatim.databaseReaderHost" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "%s" (include "nominatim.postgresql.fullname" .) -}}
{{- else -}}
    {{- if .Values.externalDatabase.readerHost -}}
        {{- printf "%s" .Values.externalDatabase.readerHost -}}
    {{- else -}}
        {{- printf "%s" .Values.externalDatabase.host -}}
    {{- end -}}
{{- end -}}
{{- end -}}


{{- define "nominatim.databasePort" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "%d" (.Values.postgresql.primary.service.ports.postgresql | int ) -}}
{{- else -}}
    {{- printf "%d" (.Values.externalDatabase.port | int ) -}}
{{- end -}}
{{- end -}}

{{- define "nominatim.databaseReaderPort" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "%d" (.Values.postgresql.primary.service.ports.postgresql | int ) -}}
{{- else -}}
    {{- if .Values.externalDatabase.readerPort -}}
        {{- printf "%d" (.Values.externalDatabase.readerPort | int ) -}}
    {{- else -}}
        {{- printf "%d" (.Values.externalDatabase.port | int ) -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- define "nominatim.databaseName" -}}
{{- "nominatim" -}}
{{- end -}}

{{- define "nominatim.databaseUser" -}}
{{- if .Values.postgresql.enabled }}
    {{- "postgres" -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.user -}}
{{- end -}}
{{- end -}}

{{- define "nominatim.databasePassword" -}}
{{- if .Values.postgresql.enabled }}
    {{- printf "%s" .Values.postgresql.auth.postgresPassword -}}
{{- else -}}
    {{- printf "%s" .Values.externalDatabase.password -}}
{{- end -}}
{{- end -}}

{{/*
Create the database URL.
*/}}
{{- define "nominatim.databaseUrl" -}}
pgsql:host={{ include "nominatim.databaseHost" . }};port={{ include "nominatim.databasePort" . }};user={{ include "nominatim.databaseUser" . }};password={{ include "nominatim.databasePassword" . }};dbname={{ include "nominatim.databaseName" . }}
{{- end }}

{{/*
Create the database readonly URL.
*/}}
{{- define "nominatim.databaseReaderUrl" -}}
pgsql:host={{ include "nominatim.databaseReaderHost" . }};port={{ include "nominatim.databaseReaderPort" . }};user={{ include "nominatim.databaseUser" . }};password={{ include "nominatim.databasePassword" . }};dbname={{ include "nominatim.databaseName" . }}
{{- end }}

{{- define "nominatim.databaseSecret" -}}
{{- printf "%s-%s" (include "nominatim.fullname" .) "postgresql" }}
{{- end }}

{{- define "nominatim.containerPort" -}}
{{- ternary 80 8080 .Values.nominatimUi.enabled -}}
{{- end }}

{{- define "nominatim.uiUrl" -}}
{{- printf "https://github.com/osm-search/nominatim-ui/releases/download/v%s/nominatim-ui-%s.tar.gz" .Values.nominatimUi.version .Values.nominatimUi.version }}
{{- end }}
