package demo.mongo.document;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

/**
 * Учебный документ заказа: маппинг Spring Data MongoDB, индексы, вложенные строки (embedding).
 */
@Document(collection = "orders")
@CompoundIndex(name = "idx_tenant_created", def = "{'tenantId': 1, 'createdAt': -1}")
@Getter
@Setter
@NoArgsConstructor
public class Order {

    @Id
    private String id;

    @Field("tenant_id")
    private Integer tenantId;

    private String status;

    @Indexed(unique = true, sparse = true)
    private String email;

    private Instant createdAt;

    private BigDecimal amount;

    private List<LineItem> lines = new ArrayList<>();

    /**
     * Вложенная строка заказа (embedding, без отдельной коллекции).
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class LineItem {

        private String sku;
        private int qty;
    }
}
