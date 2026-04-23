## 1. Запускаємо локальний postgres
```bash
cd hw3/local
docker compose up -d
```

## 2. Завантажуємо дані в тестову БД
```bash
docker exec -i hw3-postgres psql -U postgres -d periodic_table < periodic_table.sql

# перевіряємо що дані завантажились
docker exec -it hw3-postgres psql -U postgres -d periodic_table -c "\dt"
```

## 3. Розгортаємо postgres на GCP
```bash
cd hw3/terraform
terraform init
TF_VAR_db_password="<insert_pass>" terraform apply
```

## 4. Міграція
### 4.1 Створюємо дамп локальної БД
```bash
docker exec hw3-postgres pg_dump -U postgres -d periodic_table \
  --no-owner --no-acl \
  > hw3/dump.sql
```

### 4.2 Запускаємо Cloud SQL Auth Proxy:
```bash
cp ~/.config/gcloud/application_default_credentials.json /tmp/adc.json
chmod 644 /tmp/adc.json

docker run -d \
  --name cloud-sql-proxy \
  -p 5433:5432 \
  -v "/tmp/adc.json:/adc.json:ro" \
  gcr.io/cloud-sql-connectors/cloud-sql-proxy:2 \
  --address 0.0.0.0 \
  --credentials-file /adc.json \
  playground-482811:europe-central2:hw3-postgres
```

### 4.3 Рестор
```bash
docker run --rm \
  --network host \
  -e PGPASSWORD="<insert_pass>" \
  -v "$(pwd)/hw3:/backup" \
  postgres:17 \
  psql -h 127.0.0.1 -p 5433 -U hw3user -d periodic_table -f /backup/dump.sql
```

### Verify and cleanup
```bash
docker run --rm --network host -e PGPASSWORD="<insert_pass>" \
  postgres:17 psql -h 127.0.0.1 -p 5433 -U hw3user -d periodic_table -c "\dt"

docker stop cloud-sql-proxy && docker rm cloud-sql-proxy
rm /tmp/adc.json
```