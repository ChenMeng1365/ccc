const { describe, it } = require("node:test");
const assert = require("node:assert");
const { UnicodeStego } = require("../../src/unicode_stego");

describe("UnicodeStego", () => {
  const stego = new UnicodeStego();
  const sampleText =
    "Today's date is 2026-07-02. The meeting starts at 14:00, and we'll discuss the project.";

  describe("encode / decode round-trip", () => {
    it("recovers 10-bit data", () => {
      const data = 0b1010101110;
      const encoded = stego.encode(sampleText, data, 10);
      const decoded = stego.decode(encoded.stegoText, 10);
      assert.strictEqual(decoded.data, data);
    });

    it("recovers 8-bit data", () => {
      const data = 42;
      const encoded = stego.encode(sampleText, data, 8);
      const decoded = stego.decode(encoded.stegoText, 8);
      assert.strictEqual(decoded.data, data);
    });

    it("throws on insufficient capacity", () => {
      assert.throws(() => {
        stego.encode("Hello.", 0x3FF, 10);
      }, /容量/);
    });
  });

  describe("countAvailableSlots", () => {
    it("counts slots per channel", () => {
      const counts = stego.countAvailableSlots(sampleText);
      assert.ok(counts.APOSTROPHE > 0);
      assert.ok(counts.HYPHEN > 0);
      assert.ok(counts.SPACE > 0);
      assert.ok(counts.PERIOD > 0);
      assert.ok(counts.COLON > 0);
    });
  });

  describe("getCapacity", () => {
    it("returns total capacity >= 10 bits", () => {
      const capacity = stego.getCapacity(sampleText);
      assert.ok(capacity >= 10);
    });
  });

  describe("detect", () => {
    it("finds suspicious characters after encoding", () => {
      const encoded = stego.encode(sampleText, 0b1010101110, 10);
      const result = stego.detect(encoded.stegoText);
      assert.strictEqual(result.hasStego, true);
      assert.ok(result.suspicious.length > 0);
    });

    it("reports clean for plain text", () => {
      const result = stego.detect(sampleText);
      assert.strictEqual(result.hasStego, false);
    });
  });

  describe("sanitize", () => {
    it("removes all stego information", () => {
      const encoded = stego.encode(sampleText, 0b1010101110, 10);
      const sanitized = stego.sanitize(encoded.stegoText);
      const after = stego.detect(sanitized);
      assert.strictEqual(after.hasStego, false);
    });
  });

  describe("generateFingerprint / parseFingerprint", () => {
    it("round-trips environment fingerprint", () => {
      const env = {
        timeZone: "Asia/Shanghai",
        hasProxy: true,
        isChinaDomain: true,
        isAILab: false,
        platform: "darwin",
        locale: "zh-CN",
      };
      const fingerprint = stego.generateFingerprint(env);
      const parsed = stego.parseFingerprint(fingerprint);

      assert.strictEqual(parsed.isChinaTZ, true);
      assert.strictEqual(parsed.hasProxy, true);
      assert.strictEqual(parsed.osType, 2); // darwin
      assert.strictEqual(parsed.localeType, 1); // zh-CN
    });
  });

  describe("channel helpers", () => {
    it("maps chars to values and back for all channels", () => {
      const channels = ["APOSTROPHE", "HYPHEN", "SPACE", "PERIOD", "COLON"];
      for (const ch of channels) {
        for (let v = 0; v < 4; v++) {
          const char = stego.getChannelChar(ch, v);
          assert.strictEqual(stego.getChannelValue(ch, char), v);
        }
      }
    });
  });
});
