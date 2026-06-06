# MongoDB replica set + Spring Boot (demo)

Минимальное приложение для блока MongoDB доклада: **Spring Data MongoDB** (не JPA), индексы на `@Document`, derived/`@Query` репозиторий, профили **strict** / **loose** для write/read concern.

**Не sharding:** три `mongod` в compose — это **replica set** (primary + secondaries, oplog, concern). Горизонтальное деление коллекции на shards (`mongos`, shard key, chunks) в этом демо **не используется**.

Команды ниже — **из корня репозитория** (`dbSystemDesign`). Bash-скрипты сами находят `mongo-rs.compose.yml` — можно запускать и из IntelliJ (ПКМ → Run на `.sh`).

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

Профили в коде: [`MongoConcernConfig`](practice/mongo/demo-mongo/src/main/java/demo/mongo/config/MongoConcernConfig.java).

| Профиль | Write | Read concern | Read preference |
|---------|-------|--------------|-----------------|
| `strict` (по умолчанию) | `MAJORITY` + journal | `MAJORITY` | `PRIMARY` |
| `loose` | `W1` | `LOCAL` | `SECONDARY_PREFERRED` |

## Требования

- Docker Compose v2
- **Java 25** и **Maven 3.9+** установлены локально (`java -version`, `mvn -version`)
- Compose использует `network_mode: host` (удобно для Spring на хосте и URI `localhost:5571–5573`; на Linux работает из коробки)

## 1. Поднять replica set

```bash
practice/mongo/docker/mongo-rs-up.sh
```

`rs.initiate()` + `rs.status()` — см. [MongoDB Manual](https://www.mongodb.com/docs/manual/reference/method/rs.initiate/):

```bash
practice/mongo/docker/mongo-rs-init.sh
```

Повторный запуск init на уже инициализированном rs выдаст ошибку; для чистого старта: `mongo-rs-down.sh`, затем up и init снова.

Ожидаемо: один `PRIMARY`, два `SECONDARY`.

URI (дефолт в `application.yml`):

```text
mongodb://localhost:5571,localhost:5572,localhost:5573/demo?replicaSet=rs0
```

## 2. Запуск приложения

```bash
mvn -f practice/mongo/demo-mongo/pom.xml spring-boot:run -Dspring-boot.run.profiles=strict
```

Профиль `loose`:

```bash
mvn -f practice/mongo/demo-mongo/pom.xml spring-boot:run -Dspring-boot.run.profiles=loose
```

Health:

```bash
curl -s http://localhost:8080/actuator/health
```

## 3. REST-сценарии

### strict (стабильное чтение после записи)

```bash
curl -s -X POST http://localhost:8080/orders \
  -H 'Content-Type: application/json' \
  -d '{"tenantId":42,"status":"PAID","email":"a@demo.local","amount":100.50,"lines":[{"sku":"A","qty":2}]}'
```

Подставить `id` из ответа:

```bash
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

На классе [`Order`](practice/mongo/demo-mongo/src/main/java/demo/mongo/document/Order.java):

- `@CompoundIndex` на `tenantId` + `createdAt`
- `@Indexed(unique = true, sparse = true)` на `email`

Создание при старте: `spring.data.mongodb.auto-index-creation: true`.

## 5. Остановка

```bash
practice/mongo/docker/mongo-rs-down.sh
```

## Структура кода

- `practice/mongo/demo-mongo/src/.../document/Order.java`, `LineItem.java` — `@Document`, `@Field`, embedding
- `repository/OrderRepository.java` — derived + `@Query`
- `config/MongoConcernConfig.java` — concern по профилю
- `web/OrderController.java` — POST/GET без бизнес-слоя
