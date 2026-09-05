# demo-mongo

Spring Boot demo для блока MongoDB доклада (профиль **strict**).

## Запуск и домашняя работа

Не запускайте только этот модуль «в вакууме».

**Домашняя работа:** [`../HOMEWORK.md`](../HOMEWORK.md) · [`../ANSWERS.md`](../ANSWERS.md)

Кратко — **из корня** `dbSystemDesign`:

```bash
practice/mongo/docker/mongo-rs-up.sh
practice/mongo/docker/mongo-rs-init.sh
mvn -f practice/mongo/demo-mongo/pom.xml spring-boot:run \
  -Dspring-boot.run.profiles=strict
curl -s http://localhost:8080/actuator/health
```

Требуется **Java 25** и **Maven 3.9+**.

Сценарий показа на докладе: [`mongoDemo.md`](../../../mongoDemo.md).
