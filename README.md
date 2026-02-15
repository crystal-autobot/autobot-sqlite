# autobot-sqlite

SQLite plugin for Autobot - give your agents persistent database storage.

## Features

- 🗄️ **Simple API** - Just `sqlite_query` and `sqlite_migrate`
- 📁 **Migration-based** - SQL files in `data/migrations/`
- 🔒 **Sandboxed** - Restricted to workspace
- 🎯 **Skill-ready** - Works with Autobot skills

## Installation

### As Dependency

```yaml
# shard.yml
dependencies:
  autobot-sqlite:
    github: crystal-autobot/autobot-sqlite
    version: ~> 0.1.0
```

```crystal
require "autobot-sqlite"  # Auto-registers plugin
```

## Quick Start

### 1. Create Migrations

```bash
mkdir -p workspace/data/migrations
```

`workspace/data/migrations/001_create_tasks.sql`:
```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_tasks_status ON tasks(status);
```

### 2. Use in Agent

Migrations run automatically on first query:

```
User: Create a task to review PR #123

Agent: [sqlite_query(db: "tasks", query: "INSERT INTO tasks (title) VALUES ('Review PR #123')")]
       # Auto-applies 001_create_tasks.sql on first use

User: Show pending tasks

Agent: [sqlite_query(db: "tasks", query: "SELECT * FROM tasks WHERE status = 'pending'")]
```

## Create a Database Skill

Optional but recommended - teach your agent how to use databases.

`workspace/skills/database/SKILL.md`:
```markdown
---
name: database
description: "Manage SQLite databases"
---

# Database Skill

Use `sqlite_query(db: "name", query: "SQL")` to store persistent data.

Migrations in `data/migrations/` run automatically on first query.

## Examples

**Add task:**
\`\`\`
sqlite_query(db: "tasks", query: "INSERT INTO tasks (title) VALUES ('Fix bug')")
\`\`\`

**List tasks:**
\`\`\`
sqlite_query(db: "tasks", query: "SELECT * FROM tasks WHERE status = 'pending'")
\`\`\`

**Update task:**
\`\`\`
sqlite_query(db: "tasks", query: "UPDATE tasks SET status = 'done' WHERE id = 5")
\`\`\`
```

## Tools Reference

### sqlite_query(db: "name", query: "SQL")
Execute SQL query. Automatically runs pending migrations on first use.

### sqlite_migrate(db: "name")
*Optional* - Manually trigger migrations. Usually not needed since they run automatically.

```
sqlite_migrate(db: "tasks")
```

## FAQ

**Do migrations run automatically?**
Yes! Migrations in `data/migrations/*.sql` apply automatically on the first query to each database. You can also manually run `sqlite_migrate(db: "name")` if needed.

**Can I have multiple databases?**
Yes! Each `db` parameter is a separate file: `data/tasks.db`, `data/notes.db`, etc.

**How do I reset a database?**
Delete the `.db` file and re-run migrations: `rm workspace/data/tasks.db`

**What about SQL injection?**
The plugin doesn't provide parameterized queries. Teach your skill to escape single quotes: `'` → `''`

## Development

```bash
shards install
crystal spec
./bin/ameba
```

## License

MIT
