---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-configmap
  labels:
    app: limit-order-book
data:
  logfile: {{ .Values.logfile | default "" | quote }}
