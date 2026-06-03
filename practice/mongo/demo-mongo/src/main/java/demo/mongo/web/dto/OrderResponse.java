package demo.mongo.web.dto;

import demo.mongo.document.Order;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Ответ API с меткой профиля репликации для слайда/демо.
 */
@Getter
@RequiredArgsConstructor
public class OrderResponse {

    private final String replicationProfile;
    private final Order order;
}
