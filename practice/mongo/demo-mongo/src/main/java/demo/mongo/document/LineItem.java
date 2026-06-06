package demo.mongo.document;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Вложенная строка заказа (embedding, без отдельной коллекции).
 */
@Getter
@Setter
@NoArgsConstructor
public class LineItem {

    private String sku;
    private int qty;
}
