package demo.mongo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Точка входа демо-приложения MongoDB replica set.
 */
@SpringBootApplication
public class DemoMongoApplication {

    /**
     * Запуск Spring Boot.
     *
     * @param args аргументы командной строки
     */
    public static void main(String[] args) {
        SpringApplication.run(DemoMongoApplication.class, args);
    }
}
