package com.skillsetpro;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Properties;
import liquibase.changelog.ChangeLogParameters;
import liquibase.changelog.DatabaseChangeLog;
import liquibase.parser.ChangeLogParserFactory;
import liquibase.resource.ClassLoaderResourceAccessor;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

class LiquibaseChangelogTest {
  @Test
  void configuredMasterChangelogCanBeParsedWithoutDatabaseAccess() throws Exception {
    YamlPropertiesFactoryBean factory = new YamlPropertiesFactoryBean();
    factory.setResources(new ClassPathResource("application.yml"));
    Properties config = factory.getObject();
    assertThat(config).isNotNull();
    String location = config.getProperty("spring.liquibase.change-log");
    assertThat(location).startsWith("classpath:");
    String path = location.substring("classpath:".length());
    try (ClassLoaderResourceAccessor resources = new ClassLoaderResourceAccessor()) {
      DatabaseChangeLog changelog =
          ChangeLogParserFactory.getInstance()
              .getParser(path, resources)
              .parse(path, new ChangeLogParameters(), resources);
      assertThat(changelog).isNotNull();
      assertThat(changelog.getChangeSets())
          .extracting(
              changeSet ->
                  changeSet.getFilePath() + ":" + changeSet.getId() + ":" + changeSet.getAuthor())
          .doesNotHaveDuplicates();
    }
  }
}
