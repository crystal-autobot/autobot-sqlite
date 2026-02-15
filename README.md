# autobot-sqlite

SQLite plugin for Autobot - manage databases with declarative schema definitions.

## Features

- 📁 **Migration-based** - SQL files in `data/migrations/`
- 📊 **Version tracking** - Tracks applied migrations
- 🔒 **Sandboxed** - All operations via SandboxExecutor
- 🎯 **Simple API** - `sqlite_query` and `sqlite_migrate`

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  autobot:
    github: crystal-autobot/autobot
    version: ~> 0.1.0
  autobot-sqlite:
    github: crystal-autobot/autobot-sqlite
    version: ~> 0.1.0
```

## Setup

Create migration files in your workspace:

```
workspace/
├── data/
│   ├── migrations/
│   │   ├── 001_create_users.sql
│   │   ├── 002_create_posts.sql
│   │   └── 003_add_indexes.sql
│   └── app.db  (auto-created)
```

**Example migration (`001_create_users.sql`):**
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

## Usage

### 1. Run Migrations

```
> sqlite_migrate(db: "app")

Applied 3 migrations:
  ✓ 001_create_users.sql
  ✓ 002_create_posts.sql
  ✓ 003_add_indexes.sql
```

### 2. Query Database

```
> sqlite_query(db: "app", query: "SELECT * FROM users")

> sqlite_query(db: "app", query: "INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com')")

> sqlite_query(db: "app", query: "SELECT * FROM posts WHERE user_id = 1")
```

## Example: Task Tracker

**Create migrations:**

`data/migrations/001_create_tasks.sql`:
```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending',
  priority INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_status ON tasks(status);
```

**Use in agent:**
```
> Run migrations for tasks database
[sqlite_migrate(db: "tasks")]

> Create a new task
[sqlite_query(db: "tasks", query: "INSERT INTO tasks (title) VALUES ('Fix bug')")]

> Show pending tasks
[sqlite_query(db: "tasks", query: "SELECT * FROM tasks WHERE status = 'pending'")]
```

## Security

- ✅ All operations sandboxed via SandboxExecutor
- ✅ Databases restricted to workspace (`data/*.db`)
- ✅ Cannot access system files or parent directories
- ✅ Read-only mode available (block INSERT/UPDATE/DELETE)

## Migration Tracking

The tool automatically tracks applied migrations in `schema_migrations` table:

```sql
sqlite> SELECT * FROM schema_migrations;
version                    | applied_at
---------------------------|----------------------------
001_create_users.sql       | 2026-02-15 14:30:00
002_create_posts.sql       | 2026-02-15 14:30:01
003_add_indexes.sql        | 2026-02-15 14:30:02
```

**Migrations run in alphabetical order** - use numbered prefixes (001_, 002_, etc.)

## Development

```bash
# Install dependencies
shards install

# Run tests
crystal spec

# Build
crystal build src/autobot/tools/sqlite_tool.cr
```

## License

MIT
