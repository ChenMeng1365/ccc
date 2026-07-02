# frozen_string_literal: true

require_relative "../../lib/ccc/stego_encoder"

RSpec.describe StegoEncoder do
  let(:encoder) { StegoEncoder.new }

  describe "#encode / #decode round-trip" do
    it "preserves all 8 states correctly" do
      states = [
        { is_china_tz: false, domain_hit: false, keyword_hit: false },
        { is_china_tz: false, domain_hit: true,  keyword_hit: false },
        { is_china_tz: false, domain_hit: false, keyword_hit: true },
        { is_china_tz: false, domain_hit: true,  keyword_hit: true },
        { is_china_tz: true,  domain_hit: false, keyword_hit: false },
        { is_china_tz: true,  domain_hit: true,  keyword_hit: false },
        { is_china_tz: true,  domain_hit: false, keyword_hit: true },
        { is_china_tz: true,  domain_hit: true,  keyword_hit: true },
      ]

      states.each do |s|
        encoded = encoder.encode(**s)
        decoded = encoder.decode(encoded)

        expect(decoded[:is_china_tz]).to eq(s[:is_china_tz])
        expect(decoded[:domain_hit]).to  eq(s[:domain_hit])
        expect(decoded[:keyword_hit]).to eq(s[:keyword_hit])
        expect(decoded[:date]).to match(/\d{4}[\/-]\d{2}[\/-]\d{2}/)
      end
    end
  end

  describe "#china_tz?" do
    it "returns true for Asia/Shanghai" do
      expect(encoder.china_tz?("Asia/Shanghai")).to be true
    end

    it "returns true for Asia/Urumqi" do
      expect(encoder.china_tz?("Asia/Urumqi")).to be true
    end

    it "returns false for UTC" do
      expect(encoder.china_tz?("UTC")).to be false
    end
  end

  describe "#detect_proxy" do
    it "returns false for nil URL" do
      result = encoder.detect_proxy(nil)
      expect(result[:domain_hit]).to be false
      expect(result[:keyword_hit]).to be false
    end

    it "detects AI lab keywords" do
      result = encoder.detect_proxy("https://api.moonshot.ai/v1")
      expect(result[:keyword_hit]).to be true
    end

    it "detects .cn domain" do
      result = encoder.detect_proxy("https://some-proxy.cn/api")
      expect(result[:domain_hit]).to be true
    end
  end

  describe "#xor_obfuscate / #xor_deobfuscate" do
    it "round-trips arbitrary data" do
      original = "moonshot.ai|deepseek.com|zhipu.ai"
      obfuscated = encoder.xor_obfuscate(original)
      recovered = encoder.xor_deobfuscate(obfuscated)
      expect(recovered).to eq(original)
    end
  end

  describe "#demo_all_states" do
    it "returns 8 results" do
      expect(encoder.demo_all_states.length).to eq(8)
    end
  end

  describe "invalid input" do
    it "returns nil for empty decode" do
      expect(encoder.decode("")).to be_nil
    end

    it "returns nil for unmatched text" do
      expect(encoder.decode("no date here")).to be_nil
    end
  end
end
