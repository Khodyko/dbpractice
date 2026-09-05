# ANSWERS: MongoDB

Как выполнить [HOMEWORK.md](HOMEWORK.md). База: `homework`. MongoDB - локально или в контейнере.

---

## 1. Запуск и коллекции

Пример запуска в контейнере:

```bash
docker run -d --name mongo-hw -p 27017:27017 mongo:7
mongosh "mongodb://localhost:27017/homework"
```

Локальная установка - сразу `mongosh "mongodb://localhost:27017/homework"`.

После подключения:

```javascript
db.runCommand({ ping: 1 })
db.createCollection("orders")
db.createCollection("products")
```

Ожидается `{ ok: 1 }`. Коллекции появятся в `show collections`.

---

## 2. CRUD

В `mongosh`:

```javascript
use homework
db.orders.insertOne({
  customer_id: 42, status: "PAID", email: "hw-crud@example.com",
  lines: [{ sku: "A1", qty: 2 }, { sku: "B2", qty: 1 }]
})
db.orders.findOne({ email: "hw-crud@example.com" })
db.orders.updateOne({ email: "hw-crud@example.com" }, { $set: { status: "SHIPPED" } })
db.orders.updateOne({ email: "hw-crud@example.com" }, { $push: { lines: { sku: "C3", qty: 3 } } })
db.orders.findOne({ email: "hw-crud@example.com" }, { status: 1, lines: 1 })
db.orders.deleteOne({ email: "hw-crud@example.com" })
db.orders.findOne({ email: "hw-crud@example.com" })
```

После `deleteOne` последний `findOne` возвращает `null`.

---

## 3. `$lookup`

```javascript
use homework
db.products.deleteMany({})
db.products.insertMany([
  { sku: "A1", title: "Кабель USB" },
  { sku: "B2", title: "Мышь" }
])
db.orders.insertOne({
  customer_id: 42, status: "PAID", email: "hw-lookup@example.com",
  lines: [{ sku: "A1", qty: 1 }, { sku: "B2", qty: 2 }]
})
db.orders.aggregate([
  { $match: { email: "hw-lookup@example.com" } },
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

Ожидаются две строки: `A1` / «Кабель USB» и `B2` / «Мышь».

---

## 4. Индекс

```javascript
use homework
db.orders.insertMany([
  { customer_id: 1, status: "PAID", email: "hw-idx-1@example.com" },
  { customer_id: 1, status: "SHIPPED", email: "hw-idx-2@example.com" },
  { customer_id: 2, status: "PAID", email: "hw-idx-3@example.com" }
])
db.orders.getIndexes()
// только если status_1 остался с прошлого прогона:
try { db.orders.dropIndex("status_1") } catch (e) { /* индекса ещё нет */ }
db.orders.find({ status: "SHIPPED" }).explain("executionStats")
db.orders.createIndex({ status: 1 })
db.orders.find({ status: "SHIPPED" }).explain("executionStats")
db.orders.getIndexes()
```

В `explain` смотрите `queryPlanner.winningPlan`: до индекса обычно `COLLSCAN`, после - `IXSCAN` (иногда внутри `FETCH`).

---

## 5. Остановка

Если поднимали контейнер:

```bash
docker stop mongo-hw && docker rm mongo-hw
```

Если локальный сервис - остановите его штатно (`systemctl stop mongod` или аналог вашей ОС).
