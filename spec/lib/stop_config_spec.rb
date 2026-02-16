require "spec_helper"
require "stop_config"

RSpec.describe StopConfig do
  describe ".parse" do
    it "parses a single stop ID" do
      result = StopConfig.parse("15726")
      expect(result).to eq(["15726"])
    end

    it "parses multiple stop IDs" do
      result = StopConfig.parse("15726;15727;15001")
      expect(result).to eq(["15726", "15727", "15001"])
    end

    it "handles whitespace" do
      result = StopConfig.parse(" 15726 ; 15727 ")
      expect(result).to eq(["15726", "15727"])
    end

    it "deduplicates stop IDs" do
      result = StopConfig.parse("15726;15726;15727")
      expect(result).to eq(["15726", "15727"])
    end

    it "raises on nil input" do
      expect { StopConfig.parse(nil) }.to raise_error(StopConfig::ParseError, /empty or not set/)
    end

    it "raises on empty string" do
      expect { StopConfig.parse("") }.to raise_error(StopConfig::ParseError, /empty or not set/)
    end

    it "raises on whitespace-only string" do
      expect { StopConfig.parse("   ") }.to raise_error(StopConfig::ParseError, /empty or not set/)
    end

    it "raises on non-numeric stop ID" do
      expect { StopConfig.parse("abc") }.to raise_error(StopConfig::ParseError, /must be numeric/)
    end

    it "raises on mixed valid/invalid IDs" do
      expect { StopConfig.parse("15726;abc") }.to raise_error(StopConfig::ParseError, /must be numeric/)
    end

    it "skips empty entries from extra semicolons" do
      result = StopConfig.parse("15726;;15727;")
      expect(result).to eq(["15726", "15727"])
    end
  end
end
