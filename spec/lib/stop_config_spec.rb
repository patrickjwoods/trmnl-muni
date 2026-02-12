require "spec_helper"
require "stop_config"

RSpec.describe StopConfig do
  describe ".parse" do
    it "parses a single stop config" do
      result = StopConfig.parse("6:15726:Downtown")
      expect(result.length).to eq(1)
      expect(result[0].route).to eq("6")
      expect(result[0].stop_id).to eq("15726")
      expect(result[0].direction_label).to eq("Downtown")
    end

    it "parses multiple stop configs" do
      result = StopConfig.parse("6:15726:Downtown;43:15726:Downtown;6:15727:The Haight")
      expect(result.length).to eq(3)
      expect(result[0].route).to eq("6")
      expect(result[1].route).to eq("43")
      expect(result[2].stop_id).to eq("15727")
      expect(result[2].direction_label).to eq("The Haight")
    end

    it "handles whitespace in entries" do
      result = StopConfig.parse(" 6 : 15726 : Downtown ; 43 : 15726 : Downtown ")
      expect(result.length).to eq(2)
      expect(result[0].route).to eq("6")
      expect(result[0].stop_id).to eq("15726")
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

    it "raises on entry with wrong number of parts" do
      expect { StopConfig.parse("6:15726") }.to raise_error(StopConfig::ParseError, /expected format/)
    end

    it "raises on entry with blank route" do
      expect { StopConfig.parse(":15726:Downtown") }.to raise_error(StopConfig::ParseError, /Route cannot be blank/)
    end

    it "raises on entry with blank stop_id" do
      expect { StopConfig.parse("6::Downtown") }.to raise_error(StopConfig::ParseError, /Stop ID cannot be blank/)
    end

    it "raises on entry with blank direction" do
      expect { StopConfig.parse("6:15726:") }.to raise_error(StopConfig::ParseError, /expected format/)
    end
  end

  describe ".group_by_stop" do
    it "groups routes by stop_id" do
      stop_routes = StopConfig.parse("6:15726:Downtown;43:15726:Downtown;6:15727:The Haight")
      grouped = StopConfig.group_by_stop(stop_routes)

      expect(grouped.keys).to contain_exactly("15726", "15727")
      expect(grouped["15726"].length).to eq(2)
      expect(grouped["15726"].map(&:route)).to contain_exactly("6", "43")
      expect(grouped["15727"].length).to eq(1)
    end

    it "returns single-entry groups for unique stops" do
      stop_routes = StopConfig.parse("6:15726:Downtown;43:15727:Masonic")
      grouped = StopConfig.group_by_stop(stop_routes)

      expect(grouped.keys.length).to eq(2)
      grouped.each_value { |routes| expect(routes.length).to eq(1) }
    end
  end
end
