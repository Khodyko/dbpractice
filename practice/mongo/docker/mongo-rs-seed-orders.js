// Наполнение demo.orders учебными документами для explain (COLLSCAN vs IXSCAN).
// Вызывать через mongo-rs-seed.sh. Ожидает const SEED_COUNT (задаёт обёртка).
// Email: seed-NNNNN@demo.local — не пересекается с shell@ / rest@ / smoke@ показа.

const count = typeof SEED_COUNT !== "undefined" ? SEED_COUNT : 5000;
const emailPrefix = "seed-";

db = db.getSiblingDB("demo");

const removed = db.orders.deleteMany({ email: { $regex: "^" + emailPrefix } });
print("Удалены предыдущие seed-документы: " + removed.deletedCount);

const batchSize = 500;
let inserted = 0;
let shipped = 0;

for (let offset = 0; offset < count; offset += batchSize) {
  const batch = [];
  const end = Math.min(offset + batchSize, count);
  for (let i = offset; i < end; i++) {
    // ~0.5% SHIPPED — высокая избирательность для find({ status: "SHIPPED" })
    const status = i % 200 === 0 ? "SHIPPED" : i % 3 === 0 ? "CANCELLED" : "PAID";
    if (status === "SHIPPED") {
      shipped++;
    }
    batch.push({
      tenant_id: i % 10 === 0 ? 7 : 42,
      status: status,
      email: emailPrefix + String(i).padStart(5, "0") + "@demo.local",
      createdAt: new Date(Date.now() - i * 1000),
      amount: NumberDecimal(((i % 100) + 0.5).toFixed(2)),
      lines: [{ sku: "S" + (i % 20), qty: (i % 5) + 1 }]
    });
  }
  db.orders.insertMany(batch, { ordered: false });
  inserted += batch.length;
  print("Вставлено: " + inserted + " / " + count);
}

print("---");
print("Всего в orders: " + db.orders.countDocuments({}));
print("seed-документов: " + db.orders.countDocuments({ email: { $regex: "^" + emailPrefix } }));
print("status=SHIPPED (все): " + db.orders.countDocuments({ status: "SHIPPED" }));
print("Из них в этой заливке SHIPPED: ~" + shipped);
print("Готово. Дальше: explain по { status: \"SHIPPED\" }");
