const { describe, it } = require("node:test");
const assert = require("node:assert");
const { StegoEncoder } = require("../../src/stego_encoder");

describe("StegoEncoder", () => {
  const encoder = new StegoEncoder();

  describe("encode / decode round-trip", () => {
    it("preserves all 8 states", () => {
      const states = [
        { tz: false, dom: false, kw: false },
        { tz: false, dom: true,  kw: false },
        { tz: false, dom: false, kw: true },
        { tz: false, dom: true,  kw: true },
        { tz: true,  dom: false, kw: false },
        { tz: true,  dom: true,  kw: false },
        { tz: true,  dom: false, kw: true },
        { tz: true,  dom: true,  kw: true },
      ];

      for (const s of states) {
        const encoded = encoder.encode(s.tz, s.dom, s.kw);
        const decoded = encoder.decode(encoded);
        assert.strictEqual(decoded.isChinaTZ, s.tz);
        assert.strictEqual(decoded.domainHit, s.dom);
        assert.strictEqual(decoded.keywordHit, s.kw);
        assert.ok(/\d{4}[\/-]\d{2}[\/-]\d{2}/.test(decoded.date));
      }
    });
  });

  describe("detectChinaTZ", () => {
    it("is a boolean", () => {
      const result = encoder.detectChinaTZ();
      assert.strictEqual(typeof result, "boolean");
    });
  });

  describe("detectProxy", () => {
    it("returns false for null URL", () => {
      const result = encoder.detectProxy(null);
      assert.strictEqual(result.domainHit, false);
      assert.strictEqual(result.keywordHit, false);
    });

    it("detects AI lab keywords", () => {
      const result = encoder.detectProxy("https://api.moonshot.ai/v1");
      assert.strictEqual(result.keywordHit, true);
    });

    it("detects .cn domain", () => {
      const result = encoder.detectProxy("https://some-proxy.cn/api");
      assert.strictEqual(result.domainHit, true);
    });
  });

  describe("xorObfuscate / xorDeobfuscate", () => {
    it("round-trips arbitrary data", () => {
      const original = "moonshot.ai|deepseek.com|zhipu.ai";
      const obfuscated = encoder.xorObfuscate(original);
      const recovered = encoder.xorDeobfuscate(obfuscated);
      assert.strictEqual(recovered, original);
    });
  });

  describe("invalid input", () => {
    it("returns null for empty decode", () => {
      assert.strictEqual(encoder.decode(""), null);
    });

    it("returns null for unmatched text", () => {
      assert.strictEqual(encoder.decode("no date here"), null);
    });
  });
});
