# demo-mongo

Spring Boot demo для блока MongoDB доклада.

Требуется **Java 25** и **Maven 3.9+** на хосте.

Полный runbook: [`mongoDemo.md`](../../../mongoDemo.md) в корне репозитория.

Команды — из корня `dbSystemDesign`:

```bash
practice/mongo/docker/mongo-rs-up.sh
practice/mongo/docker/mongo-rs-init.sh
mvn -f practice/mongo/demo-mongo/pom.xml spring-boot:run -Dspring-boot.run.profiles=strict
```

REST-сценарии: `http/demo-orders.http`
