package com.skillsetpro;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.StringWriter;
import java.nio.file.Path;
import java.util.regex.Pattern;
import liquibase.Contexts;
import liquibase.LabelExpression;
import liquibase.Liquibase;
import liquibase.database.Database;
import liquibase.database.DatabaseFactory;
import liquibase.database.OfflineConnection;
import liquibase.resource.ClassLoaderResourceAccessor;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class DevelopmentBaselineTest {
  @TempDir Path temporaryDirectory;

  @Test
  void draftGeneratesApplicationOnlyPostgresSqlWithoutConnectingToDatabase() throws Exception {
    String history =
        temporaryDirectory.resolve("offline-history.csv").toString().replace('\\', '/');
    StringWriter output = new StringWriter();
    try (ClassLoaderResourceAccessor resources = new ClassLoaderResourceAccessor()) {
      OfflineConnection connection =
          new OfflineConnection(
              "offline:postgresql?version=18&changeLogFile=" + history, resources);
      Database database =
          DatabaseFactory.getInstance().findCorrectDatabaseImplementation(connection);
      try (Liquibase liquibase =
          new Liquibase("db/changelog/db.changelog-development.yaml", resources, database)) {
        liquibase.update(new Contexts(), new LabelExpression(), output);
      }
    }

    String sql = output.toString();
    assertThat(occurrences(sql, "(?im)^CREATE TABLE public\\.")).isEqualTo(31);
    assertThat(occurrences(sql, "(?im)^CREATE FUNCTION public\\.")).isEqualTo(3);
    assertThat(occurrences(sql, "(?im)^CREATE TRIGGER ")).isEqualTo(5);
    assertThat(occurrences(sql, "(?im)^ALTER TABLE public\\.\\w+ ENABLE ROW LEVEL SECURITY;"))
        .isEqualTo(31);
    assertThat(sql)
        .contains("CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public")
        .contains("duration_minutes integer DEFAULT 45")
        .contains("gin_trgm_ops")
        .contains("REVOKE EXECUTE ON FUNCTION public.get_question_counts() FROM PUBLIC")
        .doesNotContain("CREATE POLICY", "COPY public.", "OWNER TO", "\\restrict", "\\unrestrict");
    assertThat(occurrences(sql, "(?im)^CREATE (?:UNIQUE )?INDEX ")).isEqualTo(35);
    assertThat(occurrences(sql, "\\b(?:auth|storage|vault|realtime|extensions)\\.\\w+")).isZero();
  }

  private static long occurrences(String text, String expression) {
    return Pattern.compile(expression).matcher(text).results().count();
  }
}
