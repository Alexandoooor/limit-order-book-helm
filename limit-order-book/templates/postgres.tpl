---
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Chart.Name }}-postgres-secret
type: Opaque
stringData:
  ps_password: SecurePassword
---

apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Chart.Name }}-postgres-config
  labels:
    app: postgres
data:
  ps_db: {{ .Values.postgres.db }}
  ps_user: {{ .Values.postgres.user }}
  ps_host: {{ .Values.postgres.host }}
  ps_port: "{{ .Values.postgres.port }}"

---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ .Chart.Name }}-postgres-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data/postgres
---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Chart.Name }}-postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---

apiVersion: apps/v1
# kind: Deployment
kind: StatefulSet
metadata:
  name: {{ .Chart.Name }}-postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  key: ps_db
                  name: {{ .Chart.Name }}-postgres-config
            - name: POSTGRES_HOST
              valueFrom:
                configMapKeyRef:
                  key: ps_host
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
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: {{ .Values.volumeMounts.name }}
              mountPath: {{ .Values.volumeMounts.mountPath }}
          readinessProbe:
            tcpSocket:
              port: 5432
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: {{ .Values.volumes.name }}
          persistentVolumeClaim:
            claimName: "{{ .Chart.Name }}-{{ .Values.volumes.persistentVolumeClaim }}"
---

apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}-postgres
spec:
  type: ClusterIP
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
