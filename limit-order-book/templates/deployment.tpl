---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Chart.Name }}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
    spec:
      imagePullSecrets:
        {{- range .Values.imagePullSecrets }}
        - name: {{ . }}
        {{- end }}
      containers:
        - name: {{ .Values.image.name }}
          image: "{{ .Values.image.repository }}/{{ .Values.image.name }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          ports:
            - containerPort: {{ .Values.containerPort }}
          env:
            - name: LOGFILE
              valueFrom:
                configMapKeyRef:
                  key: logfile
                  name: {{ .Chart.Name }}-configmap

            - name: POSTGRES_HOST
              valueFrom:
                configMapKeyRef:
                  key: ps_host
                  name: {{ .Chart.Name }}-postgres-config
            - name: POSTGRES_PORT
              valueFrom:
                configMapKeyRef:
                  key: ps_port
                  name: {{ .Chart.Name }}-postgres-config
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  key: ps_db
                  name: {{ .Chart.Name }}-postgres-config
            - name: POSTGRES_USER
              valueFrom:
                configMapKeyRef:
                  key: ps_user
                  name: {{ .Chart.Name }}-postgres-config

            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: ps_password
                  name: {{ .Chart.Name }}-postgres-secret
