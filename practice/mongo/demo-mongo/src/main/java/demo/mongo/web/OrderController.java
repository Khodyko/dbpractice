package demo.mongo.web;

import demo.mongo.config.DemoReplicationProperties;
import demo.mongo.document.Order;
import demo.mongo.repository.OrderRepository;
import demo.mongo.web.dto.OrderRequest;
import demo.mongo.web.dto.OrderResponse;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Минимальный REST без бизнес-логики: save/find и метка профиля concern.
 */
@RestController
@RequestMapping("/orders")
@RequiredArgsConstructor
public class OrderController {

    private static final String PROFILE_HEADER = "X-Replication-Profile";

    private final OrderRepository orderRepository;
    private final DemoReplicationProperties replicationProperties;

    /**
     * Создание документа заказа.
     *
     * @param request поля заказа
     * @return сохранённый заказ
     */
    @PostMapping
    public ResponseEntity<OrderResponse> create(@RequestBody OrderRequest request) {
        Order order = toOrder(request);
        order.setId(UUID.randomUUID().toString());
        order.setCreatedAt(Instant.now());
        Order saved = orderRepository.save(order);
        return withProfileHeader(new OrderResponse(replicationProperties.getLabel(), saved), HttpStatus.CREATED);
    }

    /**
     * Список по status (кастомный @Query в JSON).
     *
     * @param status статус заказа
     * @return список заказов
     */
    @GetMapping("/by-status")
    public ResponseEntity<List<OrderResponse>> listByStatus(@RequestParam String status) {
        List<OrderResponse> body = orderRepository.findByStatus(status).stream()
                .map(order -> new OrderResponse(replicationProperties.getLabel(), order))
                .collect(Collectors.toList());
        HttpHeaders headers = new HttpHeaders();
        headers.set(PROFILE_HEADER, replicationProperties.getLabel());
        return ResponseEntity.ok().headers(headers).body(body);
    }

    /**
     * Чтение по идентификатору (демонстрирует read concern / read preference).
     *
     * @param id идентификатор документа
     * @return заказ или 404
     */
    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getById(@PathVariable String id) {
        return orderRepository.findById(id)
                .map(order -> withProfileHeader(
                        new OrderResponse(replicationProperties.getLabel(), order), HttpStatus.OK))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Список по tenantId (derived query).
     *
     * @param tenantId идентификатор арендатора
     * @return список заказов
     */
    @GetMapping
    public ResponseEntity<List<OrderResponse>> listByTenantId(@RequestParam Integer tenantId) {
        List<OrderResponse> body = orderRepository.findByTenantId(tenantId).stream()
                .map(order -> new OrderResponse(replicationProperties.getLabel(), order))
                .collect(Collectors.toList());
        HttpHeaders headers = new HttpHeaders();
        headers.set(PROFILE_HEADER, replicationProperties.getLabel());
        return ResponseEntity.ok().headers(headers).body(body);
    }

    private ResponseEntity<OrderResponse> withProfileHeader(OrderResponse body, HttpStatus status) {
        HttpHeaders headers = new HttpHeaders();
        headers.set(PROFILE_HEADER, replicationProperties.getLabel());
        return ResponseEntity.status(status).headers(headers).body(body);
    }

    private Order toOrder(OrderRequest request) {
        Order order = new Order();
        order.setTenantId(request.getTenantId());
        order.setStatus(request.getStatus());
        order.setEmail(request.getEmail());
        order.setAmount(request.getAmount());
        if (request.getLines() != null) {
            order.setLines(request.getLines().stream().map(line -> {
                Order.LineItem item = new Order.LineItem();
                item.setSku(line.getSku());
                item.setQty(line.getQty());
                return item;
            }).collect(Collectors.toList()));
        }
        return order;
    }
}
