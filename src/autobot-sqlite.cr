require "autobot"
require "./autobot/plugins/sqlite"

# Autobot SQLite plugin
# Provides SQLite database management with migration support
module AutobotSQLite
  VERSION = "0.1.0"

  # Auto-register plugin when required
  Autobot::Plugins::Loader.register(Autobot::Plugins::SQLitePlugin.new)
end
