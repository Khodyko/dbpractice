package demo.mongo.config;

import com.mongodb.ReadConcern;
import com.mongodb.ReadPreference;
import com.mongodb.WriteConcern;
import org.springframework.boot.autoconfigure.mongo.MongoClientSettingsBuilderCustomizer;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * Настройка write/read concern и read preference для профилей strict и loose.
 */
@Configuration
@EnableConfigurationProperties(DemoReplicationProperties.class)
public class MongoConcernConfig {

    /**
     * Строгий режим: majority на запись и чтение, чтение с primary.
     *
     * @return кастомайзер клиента MongoDB
     */
    @Bean
    @Profile("strict")
    MongoClientSettingsBuilderCustomizer strictConcernCustomizer() {
        return builder -> builder
                .writeConcern(WriteConcern.MAJORITY.withJournal(true))
                .readConcern(ReadConcern.MAJORITY)
                .readPreference(ReadPreference.primary());
    }

    /**
     * Мягкий режим: быстрая запись на primary, чтение с secondary при возможности.
     *
     * @return кастомайзер клиента MongoDB
     */
    @Bean
    @Profile("loose")
    MongoClientSettingsBuilderCustomizer looseConcernCustomizer() {
        return builder -> builder
                .writeConcern(WriteConcern.W1)
                .readConcern(ReadConcern.LOCAL)
                .readPreference(ReadPreference.secondaryPreferred());
    }
}
