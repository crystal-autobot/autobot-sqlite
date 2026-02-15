require "autobot"

module Autobot
  module Plugins
    class SQLitePlugin < Plugin
      def name : String
        "sqlite"
      end

      def description : String
        "SQLite database management with migration support"
      end

      def version : String
        "0.1.0"
      end

      def setup(context : PluginContext) : Nil
        executor = context.sandbox_executor

        context.tool_registry.register(SQLiteQueryTool.new(executor))
        context.tool_registry.register(SQLiteMigrateTool.new(executor))
      end
    end
  end

  module Tools
    class SQLiteQueryTool < Tool
      MIGRATIONS_DIR    = "data/migrations"
      QUERY_TIMEOUT     = 30
      MIGRATION_TIMEOUT = 30
      INIT_TIMEOUT      = 10
      LIST_TIMEOUT      = 10
      RECORD_TIMEOUT    = 10

      def initialize(@executor : SandboxExecutor)
      end

      def name : String
        "sqlite_query"
      end

      def description : String
        "Execute SQL queries on SQLite databases. Migrations in data/migrations/ run automatically on first use."
      end

      def parameters : ToolSchema
        ToolSchema.new(
          properties: {
            "db"    => PropertySchema.new(type: "string", description: "Database name (e.g., 'app' for data/app.db)"),
            "query" => PropertySchema.new(type: "string", description: "SQL query to execute"),
          },
          required: ["db", "query"]
        )
      end

      def execute(params : Hash(String, JSON::Any)) : ToolResult
        db_name = params["db"].as_s
        query = params["query"].as_s

        # Auto-migrate if database is new or has pending migrations
        auto_migrate_result = auto_migrate_if_needed(db_name)
        return auto_migrate_result unless auto_migrate_result.success?

        db_path = get_database_path(db_name)
        command = build_sqlite_command(db_path, query)
        @executor.exec(command, timeout: QUERY_TIMEOUT)
      end

      private def auto_migrate_if_needed(db_name : String) : ToolResult
        db_path = get_database_path(db_name)

        # Initialize schema_migrations table
        init_result = initialize_migrations_table(db_path)
        return init_result unless init_result.success?

        # Check for pending migrations
        migration_files = get_migration_files
        return ToolResult.success("") unless migration_files.is_a?(Array)
        return ToolResult.success("") if migration_files.empty?

        applied_migrations = get_applied_migrations(db_path)
        pending = migration_files.reject { |file| applied_migrations.includes?(file) }
        return ToolResult.success("") if pending.empty?

        # Apply pending migrations silently
        apply_migrations(db_path, pending)
      end

      def run_migrations(db_name : String) : ToolResult
        db_path = get_database_path(db_name)

        init_result = initialize_migrations_table(db_path)
        return init_result unless init_result.success?

        migration_files = get_migration_files
        return migration_files unless migration_files.is_a?(Array)
        return ToolResult.success("No migrations found") if migration_files.empty?

        applied_migrations = get_applied_migrations(db_path)
        pending = migration_files.reject { |file| applied_migrations.includes?(file) }
        return ToolResult.success("All migrations applied") if pending.empty?

        apply_migrations(db_path, pending)
      end

      private def initialize_migrations_table(db_path : String) : ToolResult
        command = "sqlite3 #{shell_escape(db_path)} 'CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at DATETIME DEFAULT CURRENT_TIMESTAMP);'"
        @executor.exec(command, timeout: INIT_TIMEOUT)
      end

      private def get_migration_files : Array(String) | ToolResult
        list_result = @executor.list_dir(MIGRATIONS_DIR)
        return list_result unless list_result.success?

        list_result.content.split("\n")
          .reject(&.empty?)
          .select(&.ends_with?(".sql"))
          .sort!
      end

      private def get_applied_migrations(db_path : String) : Array(String)
        command = "sqlite3 #{shell_escape(db_path)} 'SELECT version FROM schema_migrations ORDER BY version;'"
        result = @executor.exec(command, timeout: LIST_TIMEOUT)
        result.success? ? result.content.split("\n").reject(&.empty?) : [] of String
      end

      private def apply_migrations(db_path : String, migrations : Array(String)) : ToolResult
        migrations.each do |migration_file|
          result = apply_single_migration(db_path, migration_file)
          return result unless result.success?
        end

        ToolResult.success("Applied #{migrations.size} migrations")
      end

      private def apply_single_migration(db_path : String, migration_file : String) : ToolResult
        migration_path = "#{MIGRATIONS_DIR}/#{migration_file}"

        read_result = @executor.read_file(migration_path)
        return read_result unless read_result.success?

        sql = read_result.content

        run_command = "sqlite3 #{shell_escape(db_path)} #{shell_escape(sql)}"
        run_result = @executor.exec(run_command, timeout: MIGRATION_TIMEOUT)
        return run_result unless run_result.success?

        record_command = "sqlite3 #{shell_escape(db_path)} 'INSERT INTO schema_migrations (version) VALUES (#{shell_escape(migration_file)});'"
        @executor.exec(record_command, timeout: RECORD_TIMEOUT)
      end

      private def get_database_path(db_name : String) : String
        "data/#{db_name}.db"
      end

      private def build_sqlite_command(db_path : String, query : String) : String
        "sqlite3 -header -column #{shell_escape(db_path)} #{shell_escape(query)}"
      end

      private def shell_escape(arg : String) : String
        "'#{arg.gsub("'", "'\\''")}'"
      end
    end

    class SQLiteMigrateTool < Tool
      def initialize(@executor : SandboxExecutor)
      end

      def name : String
        "sqlite_migrate"
      end

      def description : String
        "Run pending SQLite migrations from data/migrations/*.sql files"
      end

      def parameters : ToolSchema
        ToolSchema.new(
          properties: {
            "db" => PropertySchema.new(type: "string", description: "Database name (e.g., 'app' for data/app.db)"),
          },
          required: ["db"]
        )
      end

      def execute(params : Hash(String, JSON::Any)) : ToolResult
        db_name = params["db"].as_s
        SQLiteQueryTool.new(@executor).run_migrations(db_name)
      end
    end
  end
end
