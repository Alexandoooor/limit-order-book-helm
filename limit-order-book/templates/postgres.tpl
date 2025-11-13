---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: limit-order-book-postgres-secret
  namespace: default
spec:
  encryptedData:
    ps_password: AgApwQtW/VqWx7R0F026a73u+OmtgAQ6PTjdX9oHTLRu9/HY23XzDulLR359BTXNLhsbujKYOkgd43CpvCfKC6IyIn/CYwrdReqNabAQ0iU10BiPa9JOYOgjcZ/53SAZOPPKPQVwBtrUQap/kbKMH7lr1K0qHHdeUzQfmVm9NoGjCahCniF8MNFwRjaeLV79HIQfIxy0dYUmivmWZfkb2E5Fkfz7NGNfTx0dlqqaVXv+0mOUcOdFdBmBeFG1Wr0xAV3pLfzMoohawqjLKvALRaXQVXlD6iUw1X2OYSfNwGZSFrL1c+tLSDki6IserKjgs5kmT2+MpQk+vIqGG1PBV1L4y9UC/i0jJTRTbzscjeLcsbX4tsb8VvVe7+XMLJq5ncQvhtwMYoDke1H0QQwXu3WoVcfPVNJElXSm+ihvvnUUgmnIH/4v7YTCPBqeOKdD/RX9kF4a+lcfg59RqNIfVjrz6J62maOyeI+H5dL3OFXxz37OSSBWhFP58ubRsdu0PHOmg1sXlS0NUA+HKcff9lxyBGXSL+IctBbCGkD8uPDVHU/T+SX6twj43q0gxkAKR8JzAXZ/77VMVuav1cIWLHApmksFFLDaY2ZOjvAt5sS4ekAm10wnGtNlKbzrgvrLd4puAb4yWfrHBmmnw5jurgsDiZ7HcX5NpUSj9IAc0Dyv+ktFImwqo2RaRQ6iclxNfwgOUKVzl4G49YbdhMXEg5hNaDAYd+Sr
  template:
    metadata:
      name: limit-order-book-postgres-secret
      namespace: default
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
