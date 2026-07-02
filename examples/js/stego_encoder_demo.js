const { StegoEncoder } = require("../../src/stego_encoder");

// === Claude Code 后门信息隐藏算法 — JS 演示 ===

const encoder = new StegoEncoder();

console.log("=== Claude Code 后门信息隐藏算法 - JS 实现 ===\n");

// 演示 1：手动编码各种状态
console.log("【1. 手动编码所有 8 种状态】");
const states = [
  { name: "非中国/未命中", tz: false, dom: false, kw: false },
  { name: "非中国/命中域名", tz: false, dom: true, kw: false },
  { name: "非中国/命中关键词", tz: false, dom: false, kw: true },
  { name: "非中国/两者命中", tz: false, dom: true, kw: true },
  { name: "中国/未命中", tz: true, dom: false, kw: false },
  { name: "中国/命中域名", tz: true, dom: true, kw: false },
  { name: "中国/命中关键词", tz: true, dom: false, kw: true },
  { name: "中国/两者命中", tz: true, dom: true, kw: true },
];

states.forEach(s => {
  const result = encoder.encode(s.tz, s.dom, s.kw);
  const decoded = encoder.decode(result);
  console.log(`${s.name.padEnd(16)} => ${result}`);
  console.log(`  解码: 中国时区=${decoded.isChinaTZ}, 域名命中=${decoded.domainHit}, 关键词命中=${decoded.keywordHit}\n`);
});

// 演示 2：自动检测（模拟）
console.log("【2. 自动检测模拟】");
const testUrls = [
  null,
  "https://api.openai.com/v1",
  "https://api.moonshot.ai/v1",
  "https://gateway.deepseek.com/v1",
  "https://some-proxy.cn/api",
];

testUrls.forEach(url => {
  const result = encoder.autoEncode(url);
  const decoded = encoder.decode(result);
  console.log(`URL: ${url || "(无代理)"}`);
  console.log(`  生成: ${result}`);
  console.log(`  解码: 中国时区=${decoded.isChinaTZ}, 域名命中=${decoded.domainHit}, 关键词命中=${decoded.keywordHit}\n`);
});

// 演示 3：XOR 混淆
console.log("【3. XOR 混淆演示 (key=91)】");
const original = "moonshot.ai|deepseek.com|zhipu.ai";
const obfuscated = encoder.xorObfuscate(original);
const recovered = encoder.xorDeobfuscate(obfuscated);
console.log(`原始:    ${original}`);
console.log(`混淆后:  ${obfuscated}`);
console.log(`恢复:    ${recovered}`);
console.log(`匹配验证: ${original === recovered ? "PASS" : "FAIL"}`);

// 演示 4：Unicode 同形字符对比
console.log("\n【4. Unicode 同形字符对比】");
const chars = [
  { name: "标准 ASCII 撇号", code: 0x0027 },
  { name: "右单引号", code: 0x2019 },
  { name: "修饰字母撇号", code: 0x02BC },
  { name: "修饰字母上标号", code: 0x02B9 },
];

chars.forEach(c => {
  const ch = String.fromCodePoint(c.code);
  console.log(`U+${c.code.toString(16).toUpperCase().padStart(4, "0")}  ${c.name.padEnd(16)}  =>  "${ch}"  (codePoint: ${ch.codePointAt(0)})`);
});
