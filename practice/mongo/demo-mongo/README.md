# MongoDB replica set + Spring Boot (demo)

Минимальное приложение для блока MongoDB доклада: **Spring Data MongoDB** (не JPA), индексы на `@Document`, derived/`@Query` репозиторий, профили **strict** / **loose** для write/read concern.

**Не sharding:** три `mongod` в compose — это **replica set** (primary + secondaries, oplog, concern). Горизонтальное деление коллекции на shards (`mongos`, shard key, chunks) в этом демо **не используется**.

## Spring Data MongoDB vs JPA

| JPA / Spring Data JPA | Spring Data MongoDB |
|----------------------|---------------------|
| `@Entity` | `@Document` |
| `@Table(name=...)` | `@Document(collection = "...")` |
| `@Id` + `@GeneratedValue` | `@Id` (`String` / `ObjectId`) |
| `@Column(name=...)` | `@Field("tenant_id")` |
| `JpaRepository` | `MongoRepository` |
| derived `findByEmail` | derived `findByTenantId` |
| `@Query("... JPQL ...")` | `@Query("{ 'status': ?0 }")` |
| `@Index` / Flyway | `@Indexed`, `@CompoundIndex`, `auto-index-creation` |

## Репликация: что подсветить

| Тема | Суть |
|------|------|
| Топология | Запись только на **primary**; secondaries — копии через oplog |
| Write concern | Когда клиент получает OK: `W1` vs `MAJORITY` (+ journal) |
| Read concern | Какие данные можно отдать: `LOCAL` vs `MAJORITY` |
| Read preference | Откуда читаем: `primary` vs `secondaryPreferred` |
| Lag | При `loose` чтение с secondary может не увидеть только что записанный документ |
| CAP | Строже — выше latency и риск отказа записи при сбое реплики |

Профили в коде: [`MongoConcernConfig`](src/main/java/demo/mongo/config/MongoConcernConfig.java).

| Профиль | Write | Read concern | Read preference |
|---------|-------|--------------|-----------------|
| `strict` (по умолчанию) | `MAJORITY` + journal | `MAJORITY` | `PRIMARY` |
| `loose` | `W1` | `LOCAL` | `SECONDARY_PREFERRED` |

## Требования

- Docker Compose v2, **Java 25**, Maven 3.9+
- Compose использует `network_mode: host` (удобно для Spring на хосте и URI `localhost:5571–5573`; на Linux работает из коробки)

Если Maven не установлен локально:

```bash
cd practice/mongo/demo-mongo
docker run --rm --network host -v "$PWD":/app -w /app \
  -e MONGO_RS_URI='mongodb://localhost:5571,localhost:5572,localhost:5573/demo?replicaSet=rs0' \
  maven:3.9-eclipse-temurin-25 mvn spring-boot:run -Dspring-boot.run.profiles=strict
```

## 1. Поднять replica set

Из **корня репозитория**:

```bash
docker compose -f practice/mongo/docker/mongo-rs.compose.yml --env-file practice/mongo/docker/.env.example up -d --wait
./practice/mongo/docker/mongo-rs-init.sh
```

Проверка: `docker compose -f practice/mongo/docker/mongo-rs.compose.yml --env-file practice/mongo/docker/.env.example exec -T mongo1 mongosh --port 5571 --quiet --eval 'rs.status().members.map(m => m.name + " " + m.stateStr)'`

Ожидаемо: один `PRIMARY`, два `SECONDARY`.

URI (из `.env.example`):

```text
mongodb://localhost:5571,localhost:5572,localhost:5573/demo?replicaSet=rs0
```

## 2. Запуск приложения

```bash
cd practice/mongo/demo-mongo
export MONGO_RS_URI='mongodb://localhost:5571,localhost:5572,localhost:5573/demo?replicaSet=rs0'
mvn spring-boot:run -Dspring-boot.run.profiles=strict
```

Профиль `loose`:

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=loose
```

Health: `curl -s http://localhost:8080/actuator/health`

## 3. REST-сценарии

### strict (стабильное чтение после записи)

```bash
curl -s -X POST http://localhost:8080/orders \
  -H 'Content-Type: application/json' \
  -d '{"tenantId":42,"status":"PAID","email":"a@demo.local","amount":100.50,"lines":[{"sku":"A","qty":2}]}'

# подставить id из ответа
curl -s -D - http://localhost:8080/orders/<id>
```

В ответе: поле `replicationProfile` и заголовок `X-Replication-Profile: strict`.

### loose (возможен replication lag)

Тот же POST/GET с профилем `loose`. Сразу после POST GET иногда вернёт **404** — повторите через 1–2 с.

```bash
curl -s 'http://localhost:8080/orders?tenantId=42'
```

Derived query: `findByTenantId`.

Кастомный `@Query` (JSON, не JPQL):

```bash
curl -s 'http://localhost:8080/orders/by-status?status=PAID'
```

При повторном POST с тем же `email` MongoDB вернёт ошибку уникального индекса (`@Indexed unique sparse`).

## 4. Индексы

На классе [`Order`](src/main/java/demo/mongo/document/Order.java):

- `@CompoundIndex` на `tenantId` + `createdAt`
- `@Indexed(unique = true, sparse = true)` на `email`

Создание при старте: `spring.data.mongodb.auto-index-creation: true`.

## 5. Остановка

```bash
# из корня репозитория
docker compose -f practice/mongo/docker/mongo-rs.compose.yml --env-file practice/mongo/docker/.env.example down -v
```

## Структура кода

- `document/Order.java`, `document/LineItem.java` — `@Document`, `@Field`, embedding
- `repository/OrderRepository.java` — derived + `@Query`
- `config/MongoConcernConfig.java` — concern по профилю
- `web/OrderController.java` — POST/GET без бизнес-слоя
