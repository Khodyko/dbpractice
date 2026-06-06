package demo.mongo.web.dto;

import demo.mongo.document.Order;

/**
 * Ответ API с меткой профиля репликации для слайда/демо.
 *
 * @param replicationProfile метка профиля strict/loose
 * @param order              документ заказа
 */
public record OrderResponse(String replicationProfile, Order order) {
}
