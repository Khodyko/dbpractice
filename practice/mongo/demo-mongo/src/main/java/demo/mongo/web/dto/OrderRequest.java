package demo.mongo.web.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * Тело POST /orders без бизнес-валидации (учебный DTO).
 *
 * @param tenantId идентификатор арендатора
 * @param status   статус заказа
 * @param email    email (уникальный sparse-индекс)
 * @param amount   сумма
 * @param lines    строки заказа
 */
public record OrderRequest(
        Integer tenantId,
        String status,
        String email,
        BigDecimal amount,
        List<LineItemRequest> lines) {
}
