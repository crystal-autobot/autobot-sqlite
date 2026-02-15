require "./spec_helper"

describe Autobot::Plugins::SQLitePlugin do
  describe "#name" do
    it "returns plugin name" do
      plugin = Autobot::Plugins::SQLitePlugin.new
      plugin.name.should eq("sqlite")
    end
  end

  describe "#description" do
    it "returns plugin description" do
      plugin = Autobot::Plugins::SQLitePlugin.new
      plugin.description.should contain("SQLite")
    end
  end

  describe "#version" do
    it "returns plugin version" do
      plugin = Autobot::Plugins::SQLitePlugin.new
      plugin.version.should eq("0.1.0")
    end
  end
end
