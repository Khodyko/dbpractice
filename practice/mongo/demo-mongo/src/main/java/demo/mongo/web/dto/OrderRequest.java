package demo.mongo.web.dto;

import java.math.BigDecimal;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Тело POST /orders без бизнес-валидации (учебный DTO).
 */
@Getter
@Setter
@NoArgsConstructor
public class OrderRequest {

    private Integer tenantId;
    private String status;
    private String email;
    private BigDecimal amount;
    private List<LineItemRequest> lines;

    /**
     * Строка заказа во входном DTO.
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class LineItemRequest {

        private String sku;
        private int qty;
    }
}
