package demo.mongo.web.dto;

/**
 * Строка заказа во входном DTO.
 *
 * @param sku артикул
 * @param qty количество
 */
public record LineItemRequest(String sku, int qty) {
}
