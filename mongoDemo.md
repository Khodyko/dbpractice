# MongoDB: сценарий доклада

Пошаговый runbook для блока «Практика» в [`текстДокладаMongo.md`](текстДокладаMongo.md).
Команды — **из корня** репозитория `dbSystemDesign`.

**Стенд:** replica set на Linux с `network_mode: host` (порты `5571`–`5573` на `localhost`).
Для macOS/Windows - bridge: `practice/mongo/docker/mongo-rs-up-bridge.sh` и `mongo-rs-init-bridge.sh`, либо WSL2.
Домашка не зависит от этого стенда: [`practice/mongo/HOMEWORK.md`](practice/mongo/HOMEWORK.md).

---

## 1. Поднять replica set

```bash
practice/mongo/docker/mongo-rs-up.sh
practice/mongo/docker/mongo-rs-init.sh
```

Проверка:

```bash
docker compose -f practice/mongo/docker/mongo-rs.compose.yml exec -T mongo1 \
  mongosh --port 5571 --quiet --eval 'rs.status().members.forEach(m => print(m.name + " -> " + m.stateStr))'
```

---

## 2. Запустить demo-mongo

Требуется **Java 25** и **Maven 3.9+**. Подробнее: [`practice/mongo/demo-mongo/README.md`](practice/mongo/demo-mongo/README.md).

```bash
mvn -f practice/mongo/demo-mongo/pom.xml spring-boot:run \
  -Dspring-boot.run.profiles=strict
```

Healthcheck:

```bash
curl -s http://localhost:8080/actuator/health
```

---

## 3. Подключиться к mongosh

```bash
docker compose -f practice/mongo/docker/mongo-rs.compose.yml exec -it mongo1 mongosh --port 5571 demo
```

Или локально:

```bash
mongosh "mongodb://localhost:5571,localhost:5572,localhost:5573/demo?replicaSet=rs0"
```

```javascript
db.runCommand({ ping: 1 })
```

---

## 4. (Опционально) Наполнить orders для explain

Для наглядного COLLSCAN/IXSCAN на большом объёме:

```bash
practice/mongo/docker/mongo-rs-seed.sh
```

---

## 5a. Shell CRUD на demo.orders

В mongosh (`use demo`). Email для показа — `talk-crud@demo.local`:

```javascript
use demo

db.orders.insertOne({
  tenant_id: 42,
  status: "PAID",
  email: "talk-crud@demo.local",
  lines: [{ sku: "A1", qty: 2 }, { sku: "B2", qty: 1 }]
})

db.orders.findOne({ email: "talk-crud@demo.local" })

db.orders.updateOne(
  { email: "talk-crud@demo.local" },
  { $set: { status: "SHIPPED" } }
)

db.orders.updateOne(
  { email: "talk-crud@demo.local" },
  { $push: { lines: { sku: "C3", qty: 3 } } }
)

db.orders.findOne({ email: "talk-crud@demo.local" }, { status: 1, lines: 1 })

db.orders.deleteOne({ email: "talk-crud@demo.local" })
```

---

## 5b. Индексы и explain

```javascript
use demo

db.orders.getIndexes()

db.orders.find({ status: "SHIPPED" }).explain("executionStats")
// queryPlanner.winningPlan.stage — до ручного createIndex часто COLLSCAN

db.orders.createIndex({ status: 1 })

db.orders.find({ status: "SHIPPED" }).explain("executionStats")
// после индекса — IXSCAN

db.orders.getIndexes()
// idx_tenant_created, email_1 — от Spring (аннотации в Order)
```

---

## 5c. $lookup и REST

**$lookup** (справочник + заказ):

```javascript
use demo

db.products.insertMany([
  { sku: "A1", title: "Кабель USB" },
  { sku: "B2", title: "Мышь" }
])

db.orders.insertOne({
  tenant_id: 42,
  status: "PAID",
  email: "talk-lookup@demo.local",
  lines: [{ sku: "A1", qty: 1 }, { sku: "B2", qty: 2 }]
})

db.orders.aggregate([
  { $match: { email: "talk-lookup@demo.local" } },
  { $unwind: "$lines" },
  { $lookup: {
      from: "products",
      localField: "lines.sku",
      foreignField: "sku",
      as: "productInfo"
  }},
  { $project: {
      sku: "$lines.sku",
      qty: "$lines.qty",
      title: { $arrayElemAt: ["$productInfo.title", 0] }
  }}
])
```

**REST** (в другом терминале, пока demo-mongo запущен):

```bash
curl -s "http://localhost:8080/orders?tenantId=42"
curl -s -X POST http://localhost:8080/orders \
  -H 'Content-Type: application/json' \
  -d '{"tenantId":42,"status":"PAID","email":"talk-rest@demo.local","amount":99.50,"lines":[{"sku":"A1","qty":1}]}'
```

---

## 6. Остановка

```bash
# Ctrl+C — demo-mongo
practice/mongo/docker/mongo-rs-down.sh
```

---

**Домашняя работа (любая MongoDB):** [`practice/mongo/HOMEWORK.md`](practice/mongo/HOMEWORK.md) · [`ANSWERS.md`](practice/mongo/ANSWERS.md)

**Общий README стенда:** [`README.md`](README.md)
