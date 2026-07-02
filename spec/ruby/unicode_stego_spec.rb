# frozen_string_literal: true

require_relative "../../lib/ccc/unicode_stego"

RSpec.describe UnicodeStego do
  let(:stego) { UnicodeStego.new }
  let(:sample_text) do
    "Today's date is 2026-07-02. The meeting starts at 14:00, and we'll discuss the project."
  end

  describe "#encode / #decode round-trip" do
    it "recovers 10-bit data" do
      data = 0b1010101110
      encoded = stego.encode(sample_text, data, 10)
      decoded = stego.decode(encoded[:stego_text], 10)
      expect(decoded[:data]).to eq(data)
    end

    it "recovers 8-bit data" do
      data = 42
      encoded = stego.encode(sample_text, data, 8)
      decoded = stego.decode(encoded[:stego_text], 8)
      expect(decoded[:data]).to eq(data)
    end

    it "raises on insufficient capacity" do
      short_text = "Hello."
      expect {
        stego.encode(short_text, 0x3FF, 10)
      }.to raise_error(/容量/)
    end
  end

  describe "#count_available_slots" do
    it "counts slots per channel" do
      counts = stego.count_available_slots(sample_text)
      expect(counts[:apostrophe]).to be > 0
      expect(counts[:hyphen]).to be > 0
      expect(counts[:space]).to be > 0
      expect(counts[:period]).to be > 0
      expect(counts[:colon]).to be > 0
    end
  end

  describe "#get_capacity" do
    it "returns total capacity in bits" do
      capacity = stego.get_capacity(sample_text)
      expect(capacity).to be >= 10
    end
  end

  describe "#detect" do
    it "finds suspicious characters after encoding" do
      encoded = stego.encode(sample_text, 0b1010101110, 10)
      result = stego.detect(encoded[:stego_text])
      expect(result[:has_stego]).to be true
      expect(result[:suspicious]).not_to be_empty
    end

    it "reports clean for plain text" do
      result = stego.detect(sample_text)
      expect(result[:has_stego]).to be false
    end
  end

  describe "#sanitize" do
    it "removes all stego information" do
      encoded = stego.encode(sample_text, 0b1010101110, 10)
      sanitized = stego.sanitize(encoded[:stego_text])
      after = stego.detect(sanitized)
      expect(after[:has_stego]).to be false
    end
  end

  describe "#generate_fingerprint / #parse_fingerprint" do
    it "round-trips environment fingerprint" do
      env = {
        time_zone: "Asia/Shanghai",
        has_proxy: true,
        is_china_domain: true,
        is_ai_lab: false,
        platform: "darwin",
        locale: "zh-CN",
      }
      fingerprint = stego.generate_fingerprint(env)
      parsed = stego.parse_fingerprint(fingerprint)

      expect(parsed[:is_china_tz]).to be true
      expect(parsed[:has_proxy]).to be true
      expect(parsed[:os_type]).to eq(2) # darwin
      expect(parsed[:locale_type]).to eq(1) # zh-CN
    end
  end

  describe "channel helpers" do
    it "maps chars to values and back" do
      %i[apostrophe hyphen space period colon].each do |ch|
        (0..3).each do |v|
          char = stego.get_channel_char(ch, v)
          expect(stego.get_channel_value(ch, char)).to eq(v)
        end
      end
    end
  end
end
