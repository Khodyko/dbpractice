package demo.mongo.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * Логирует активные concern/preference при старте (для демо на докладе).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ConcernStartupLogger implements ApplicationRunner {

    private final DemoReplicationProperties replicationProperties;

    @Value("${spring.data.mongodb.uri}")
    private String mongoUri;

    @Override
    public void run(ApplicationArguments args) {
        String label = replicationProperties.getLabel();
        log.info("=== MongoDB replication demo profile: {} ===", label);
        log.info("URI: {}", mongoUri);
        if ("loose".equals(label)) {
            log.info("Active settings (MongoConcernConfig @Profile loose): write W1, read LOCAL, secondaryPreferred");
        } else {
            log.info("Active settings (MongoConcernConfig @Profile strict): write MAJORITY+journal, read MAJORITY, primary");
        }
        log.info("Driver also logs MongoClientSettings at INFO on startup (org.mongodb.driver.client)");
    }
}
