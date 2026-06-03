package demo.mongo.web;

import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Обработка нарушения уникального индекса email (демо sparse unique @Indexed).
 */
@Slf4j
@RestControllerAdvice
public class DemoExceptionHandler {

    /**
     * Дубликат email — ответ 409 вместо stack trace.
     *
     * @param ex исключение Spring Data MongoDB
     * @return тело ошибки
     */
    @ExceptionHandler(DuplicateKeyException.class)
    public ResponseEntity<String> handleDuplicateKey(DuplicateKeyException ex) {
        log.warn("Duplicate key: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body("email already exists (unique index)");
    }
}
