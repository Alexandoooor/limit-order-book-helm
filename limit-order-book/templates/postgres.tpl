---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: {{ .Chart.Name }}-postgres-secret
spec:
  encryptedData:
    ps_password: AgBfMQlUxIAcVka+sEmsCB/L73hyPL4kDv+iyCSTC+YEbqrnj7v3ZXj3ekf3a3o9H01+4Xbg7YJCXyGc9XCA00PUGmeoJfV/8XYpBt+othq2M3gHpgqkSSogvVDn19TJw/aVB9q5m0D2BmiFWkEcxJtHVYXd8vd7Nb6sjPajlKKBCYqy8ZCZkSoIW+Nhhd821rl8SCLDMsM63iCvjdZsoSoD2rrJ3sne9757X/lqCg616anNehHos1bwAXhnoj7kcVAwBkN06zT+AnkWwRuH1uOSR75kfG/wXAYS8g76RrF8G1ilI4521JQuo58TGYh810ugxyXnuUXsO904H+vQSDLEbKjrOzDWzIPNj4Q1PkCqgRgdNybN5dm06bROhIrUyVPQO0M/cOfPSTMPVNZCbI8EFc0oON3d71CIRBEMKRklSvplRDDTc/AWa/L6iQwqTStfCjpTsV7BgsyUX383iEjhSCDBZDyWUpg253HqtIwKzklbStsYigB7FMnefr49JErNE7AQwdzOdMDgGUvI9v5quuytORtzeUqq2wiBtmV0sVP6sg60vmAVQG2jL8/DBlsSD1T0dZWTYs+Q3tAugAAjw6VFiZPDFldWWKMzjlzKJwFV7tFyft4m3x8Wi/zwmlyd7vmHvaGp2gp8B9mN5vt+PJJyvgNKnRMjVEFxCcvcBCQAjL7JKWzz8r6+9diXIzXlagZ0mgTeh/1z9D3Vi20Qt6BKScNK
  template:
    metadata:
      name: {{ .Chart.Name }}-postgres-secret
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
