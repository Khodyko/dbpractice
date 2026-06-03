package demo.mongo.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Метка активного профиля репликации для ответов REST.
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "demo.replication")
public class DemoReplicationProperties {

    private String label = "strict";
}
