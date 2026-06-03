package demo.mongo.repository;

import demo.mongo.document.Order;
import java.util.List;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

/**
 * Репозиторий заказов: derived-методы и кастомный запрос в JSON (аналог Spring Data JPA).
 */
public interface OrderRepository extends MongoRepository<Order, String> {

    /**
     * Поиск по tenantId (имя метода → фильтр MongoDB).
     *
     * @param tenantId идентификатор арендатора
     * @return список заказов
     */
    List<Order> findByTenantId(Integer tenantId);

    /**
     * Кастомный фильтр по статусу (JSON вместо JPQL).
     *
     * @param status статус заказа
     * @return список заказов
     */
    @Query("{ 'status': ?0 }")
    List<Order> findByStatus(String status);
}
