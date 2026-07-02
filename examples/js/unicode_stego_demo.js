const { UnicodeStego } = require("../../src/unicode_stego");

// === Unicode 隐写编码方案 — JS 演示 ===

const stego = new UnicodeStego();

console.log("=== Unicode 隐写编码方案 - JS 实现 ===\n");

// 演示 1：字符映射表
console.log("【1. Unicode 同形字符映射表】");
for (const [name, channel] of Object.entries(stego.CHANNELS)) {
  console.log(`\n通道: ${name} (${channel.name})`);
  for (const char of channel.chars) {
    const code = `U+${char.code.toString(16).toUpperCase().padStart(4, "0")}`;
    console.log(`  ${code}  ${char.name.padEnd(16)}  => "${char.char}"`);
  }
}

// 演示 2：容量计算
console.log("\n\n【2. 文本容量计算】");
const sampleText = "Today's date is 2026-07-02. The meeting starts at 14:00, and we'll discuss the project.";
console.log(`示例文本: "${sampleText}"`);
const capacity = stego.getCapacity(sampleText);
const counts = stego.countAvailableSlots(sampleText);
console.log("各通道可用字符数:", counts);
console.log(`总编码容量: ${capacity} bits (${capacity / 8} bytes)`);

// 演示 3：编码与解码
console.log("\n\n【3. 编码与解码演示】");
const testData = 0b1010101110; // 10-bit 测试数据
console.log(`待编码数据: ${testData} (二进制: ${testData.toString(2).padStart(10, "0")})`);

const encoded = stego.encode(sampleText, testData, 10);
console.log(`\n隐写文本: "${encoded.stegoText}"`);
console.log("使用的通道:", Object.keys(encoded.usedChannels));

const decoded = stego.decode(encoded.stegoText, 10);
console.log(`\n解码数据: ${decoded.data} (二进制: ${decoded.data.toString(2).padStart(10, "0")})`);
console.log(`数据匹配: ${testData === decoded.data ? "PASS" : "FAIL"}`);

// 演示 4：视觉对比
console.log("\n\n【4. 视觉对比（肉眼不可区分）】");
console.log("原始文本:", sampleText);
console.log("隐写文本:", encoded.stegoText);
console.log("两者在大多数字体下视觉上完全相同！");

// 演示 5：环境指纹编码
console.log("\n\n【5. 环境指纹编码（模拟 Claude Code）】");
const env = {
  timeZone: "Asia/Shanghai",
  hasProxy: true,
  isChinaDomain: true,
  isAILab: false,
  platform: "darwin",
  locale: "zh-CN",
};
const fingerprint = stego.generateFingerprint(env);
console.log("环境信息:", env);
console.log(`生成指纹: ${fingerprint} (二进制: ${fingerprint.toString(2).padStart(10, "0")})`);

const fingerprintEncoded = stego.encode(sampleText, fingerprint, 10);
console.log("\n嵌入指纹后的文本:", fingerprintEncoded.stegoText);

const fingerprintDecoded = stego.decode(fingerprintEncoded.stegoText, 10);
const parsed = stego.parseFingerprint(fingerprintDecoded.data);
console.log("\n解析指纹:", parsed);

// 演示 6：检测与防御
console.log("\n\n【6. 检测与防御】");
const detection = stego.detect(fingerprintEncoded.stegoText);
console.log("检测结果:", detection.summary);
if (detection.suspicious.length > 0) {
  console.log("可疑字符详情:");
  detection.suspicious.forEach(s => {
    console.log(`  ${s.channel}: ${s.name} (${s.code}) × ${s.count}`);
  });
}

const sanitized = stego.sanitize(fingerprintEncoded.stegoText);
console.log("\n清理后的文本:", sanitized);
const afterSanitize = stego.detect(sanitized);
console.log("清理后检测:", afterSanitize.summary);

// 演示 7：水印应用
console.log("\n\n【7. 文档水印应用】");
const document = "机密文件 - 仅供内部使用。请勿外传。";
const watermarkId = 42; // 接收者 ID
const watermarked = stego.encode(document, watermarkId, 10);
console.log(`原文档: "${document}"`);
console.log(`水印 ID: ${watermarkId}`);
console.log(`水印文档: "${watermarked.stegoText}"`);

const extracted = stego.decode(watermarked.stegoText, 10);
console.log(`提取水印: ${extracted.data}`);
console.log(`水印验证: ${watermarkId === extracted.data ? "PASS" : "FAIL"}`);
