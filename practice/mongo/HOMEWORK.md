# HOMEWORK: MongoDB

Практика по темам: модель документа, CRUD, связь коллекций через `$lookup`, индексы.

Отмечай пункты по мере выполнения. Ничего сдавать не нужно.

Имя базы в примерах: `homework`. Подключение через `mongosh`.

---

## 1. Запуск и коллекции

- [ ] Поднимите MongoDB локально или в контейнере
- [ ] Подключитесь через `mongosh` к базе `homework`
- [ ] Проверьте связь: `db.runCommand({ ping: 1 })` - ожидается `{ ok: 1 }`
- [ ] Создайте коллекцию `orders`
- [ ] Создайте коллекцию `products`

Пример создания коллекций:

```javascript
db.createCollection("orders")
db.createCollection("products")
```

---

## 2. CRUD

- [ ] Добавьте в коллекцию `orders` новый документ:
  ```json
  {
    "customer_id": 42,
    "status": "PAID",
    "email": "hw-crud@example.com",
    "lines": [
      { "sku": "A1", "qty": 2 },
      { "sku": "B2", "qty": 1 }
    ]
  }
  ```
- [ ] Найдите документ с `email` = `hw-crud@example.com` - в ответе те же `status`, `email` и **две** позиции в `lines`
- [ ] Измените у этого документа поле `status` на `SHIPPED`
- [ ] Добавьте в массив `lines` третью позицию `{ "sku": "C3", "qty": 3 }` - итого **3** элемента
- [ ] Снова прочитайте документ с `email` = `hw-crud@example.com` - `status` = `SHIPPED`, в `lines` три позиции
- [ ] Удалите документ с `email` = `hw-crud@example.com`
- [ ] Убедитесь, что поиск по `email` = `hw-crud@example.com` больше ничего не возвращает

---

## 3. `$lookup` - связь заказа со справочником товаров

- [ ] Заполните коллекцию `products` двумя товарами:
  ```json
  [
    { "sku": "A1", "title": "Кабель USB" },
    { "sku": "B2", "title": "Мышь" }
  ]
  ```
- [ ] Добавьте в `orders` заказ - в каждой строке `lines[]` только `sku` и `qty`, **без** `title`:
  ```json
  {
    "customer_id": 42,
    "status": "PAID",
    "email": "hw-lookup@example.com",
    "lines": [
      { "sku": "A1", "qty": 1 },
      { "sku": "B2", "qty": 2 }
    ]
  }
  ```
- [ ] Прочитайте этот заказ так, чтобы **каждая** строка из `lines` содержала `sku`, `qty` и `title` из справочника `products` (связь по полю `sku`). В результате - **две** строки, у каждой есть и артикул, и название товара

**Подсказка:** aggregation pipeline - `$match` → `$unwind` по `lines` → `$lookup` в `products` по `sku` → `$project`. Готовый скрипт для сверки - в [ANSWERS.md](ANSWERS.md) §3.

---

## 4. Индекс и план запроса

- [ ] Добавьте в `orders` несколько документов с разными значениями `status` (минимум `PAID` и `SHIPPED`), например:
  ```json
  [
    { "customer_id": 1, "status": "PAID", "email": "hw-idx-1@example.com" },
    { "customer_id": 1, "status": "SHIPPED", "email": "hw-idx-2@example.com" },
    { "customer_id": 2, "status": "PAID", "email": "hw-idx-3@example.com" }
  ]
  ```
- [ ] Посмотрите, какие индексы сейчас есть на коллекции `orders`
- [ ] Если с прошлого прогона остался индекс по полю `status` - уберите его, чтобы сравнение было честным
- [ ] Найдите все заказы со `status` = `SHIPPED` и **до** создания индекса посмотрите план запроса - зафиксируйте тип сканирования (обычно полный обход коллекции, COLLSCAN):
  ```javascript
  db.orders.find({ status: "SHIPPED" }).explain("executionStats")
  ```
  Смотрите `queryPlanner.winningPlan.stage`: до индекса обычно `COLLSCAN`, после - `IXSCAN`.

- [ ] Создайте восходящий индекс на поле `status`
- [ ] Повторите тот же поиск со `status` = `SHIPPED` и посмотрите план **после** индекса - тип сканирования изменился (ожидается обход по индексу, IXSCAN)
- [ ] Убедитесь, что в списке индексов появился новый индекс на `status`

---

## 5. Остановка

- [ ] Остановите MongoDB тем способом, которым поднимали

---

Далее - [HOMEWORK PostgreSQL](../postgres/HOMEWORK.md)