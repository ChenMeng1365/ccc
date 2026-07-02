# Unicode 隐写编码方案设计

## 一、方案概述

基于 Claude Code 后门事件的技术原理，设计一种通用的 Unicode 隐写编码方案。该方案利用 Unicode 同形字符（homoglyphs）在文本中嵌入隐藏信息，具有**肉眼不可区分、语义保持、绕过简单检测**的特点。

## 二、编码通道设计

### 2.1 核心思想

选择多组 Unicode 同形字符（视觉上几乎相同，但编码不同），每组字符对应一个 bit 或一组状态。通过替换文本中的特定字符来编码信息。

### 2.2 字符映射表

#### 通道 A：撇号变体（2 bits）

| 编码值 | Unicode | 字符 | 名称 | 说明 |
|--------|---------|------|------|------|
| 00 | U+0027 | `'` | 标准 ASCII 撇号 | 基准字符 |
| 01 | U+2019 | `'` | 右单引号 | 视觉上与标准撇号几乎相同 |
| 10 | U+02BC | `'` | 修饰字母撇号 | 用于音标，字形极相似 |
| 11 | U+02B9 | `′` | 修饰字母上标号 | 略高，但大多数字体下难区分 |

#### 通道 B：短横线变体（2 bits）

| 编码值 | Unicode | 字符 | 名称 | 说明 |
|--------|---------|------|------|------|
| 00 | U+002D | `-` | 标准连字符 | 基准字符 |
| 01 | U+2010 | `‐` | 连字符 | 与标准连字符几乎相同 |
| 10 | U+2011 | `‑` | 非断连字符 | 排版用，视觉上无区别 |
| 11 | U+2212 | `−` | 减号 | 数学符号，宽度略大 |

#### 通道 C：空格变体（2 bits）

| 编码值 | Unicode | 字符 | 名称 | 说明 |
|--------|---------|------|------|------|
| 00 | U+0020 | ` ` | 标准空格 | 基准字符 |
| 01 | U+00A0 | ` ` | 不间断空格 | 与标准空格视觉上相同 |
| 10 | U+2002 | ` ` | En 空格 | 宽度为 em 的一半 |
| 11 | U+2003 | ` ` | Em 空格 | 全角空格宽度 |

#### 通道 D：句号变体（2 bits）

| 编码值 | Unicode | 字符 | 名称 | 说明 |
|--------|---------|------|------|------|
| 00 | U+002E | `.` | 标准句点 | 基准字符 |
| 01 | U+2024 | `․` | 一点前导 | 视觉上与句点相同 |
| 10 | U+06D4 | `۔` | 阿拉伯句号 | 阿拉伯语中的句号 |
| 11 | U+3002 | `。` | 中文句号 | 东亚文字中的句号 |

#### 通道 E：冒号变体（2 bits）

| 编码值 | Unicode | 字符 | 名称 | 说明 |
|--------|---------|------|------|------|
| 00 | U+003A | `:` | 标准冒号 | 基准字符 |
| 01 | U+2236 | `∶` | 比例符号 | 数学符号，视觉上相同 |
| 10 | U+02F8 | `˸` | 修饰字母冒号 | 用于音标 |
| 11 | U+A789 | `꞉` | 修饰字母冒号 | 拉丁扩展 |

### 2.3 组合编码能力

5 个通道 × 2 bits = **10 bits** 的编码空间，可表示 1024 种状态。

可用于编码：
- 用户环境指纹（时区、语言、代理等）
- 会话标识（10 bits 可区分 1024 个会话）
- 版本/配置信息
- 水印信息（追踪文本泄露来源）

## 三、编码策略

### 3.1 文本选择策略

不是所有文本都适合编码，需要选择：
1. **高频出现的标点**：撇号、短横线、空格、句号、冒号
2. **语义不敏感的位置**：日期格式、固定模板文本
3. **足够的长度**：确保有足够的编码位

### 3.2 编码流程

```
输入：明文文本 + 待编码数据（10 bits）
输出：隐写文本

步骤：
1. 扫描文本，统计各通道可用字符数量
2. 根据待编码数据长度，选择足够的通道
3. 按优先级（撇号 > 短横线 > 空格 > 句号 > 冒号）分配编码位
4. 从高位到低位依次替换字符
5. 输出隐写文本
```

### 3.3 解码流程

```
输入：隐写文本
输出：解码数据（10 bits）

步骤：
1. 扫描文本，识别各通道使用的变体字符
2. 将每个变体映射回对应的编码值
3. 按通道优先级组合成完整数据
4. 输出解码结果
```

### 3.4 代码示例

```javascript
const stego = new UnicodeStego();

// 编码
const result = stego.encode(text, data, bits);
// => { stegoText, usedChannels, data, bits, capacity }

// 解码
const decoded = stego.decode(stegoText, bits);
// => { data, usedChannels, bits, allValues }

// 检测
const detection = stego.detect(text);
// => { hasStego, suspicious, summary }

// 防御（清除隐写）
const clean = stego.sanitize(text);

// 环境指纹
const fingerprint = stego.generateFingerprint(env);
const parsed = stego.parseFingerprint(fingerprint);
```

```ruby
stego = UnicodeStego.new

# 编码
result = stego.encode(text, data, bits)
# => { stego_text:, used_channels:, data:, bits:, capacity: }

# 解码
decoded = stego.decode(stego_text, bits)
# => { data:, used_channels:, bits:, all_values: }

# 检测
detection = stego.detect(text)
# => { has_stego:, suspicious:, summary: }

# 防御（清除隐写）
clean = stego.sanitize(text)

# 环境指纹
fingerprint = stego.generate_fingerprint(env)
parsed = stego.parse_fingerprint(fingerprint)
```

#### 基本编码解码

```javascript
const text = "Today's date is 2026-07-02. The meeting starts at 14:00.";
const data = 0b1010101110; // 10-bit 数据

const encoded = stego.encode(text, data, 10);
console.log(encoded.stegoText);
// => "Today's date is 2026/07/02. The meeting starts at 14∶00."
// 注意：肉眼几乎看不出变化！

const decoded = stego.decode(encoded.stegoText, 10);
console.log(decoded.data === data); // true
```

#### 指纹变量

```javascript
const env = {
  timeZone: "Asia/Shanghai",
  hasProxy: true,
  isChinaDomain: true,
  isAILab: false,
  platform: "darwin",
  locale: "zh-CN",
};

const fingerprint = stego.generateFingerprint(env);
// => 例如 687 (二进制: 1010101111)

const result = stego.encode(systemPrompt, fingerprint, 10);
// 将环境指纹隐写进系统提示词
```

#### 文档水印

```javascript
const document = "机密文件 - 仅供内部使用。请勿外传。";
const watermarkId = 42; // 接收者 ID

const watermarked = stego.encode(document, watermarkId, 10);
// 分发带水印的文档

const extracted = stego.decode(leakedDocument, 10);
// => 42，追踪到泄露来源
```

#### 监测与清除

```javascript
// 检测隐写
const detection = stego.detect(suspiciousText);
if (detection.hasStego) {
  console.log("发现可疑 Unicode 字符！");
  detection.suspicious.forEach(s => {
    console.log(`${s.channel}: ${s.name} (${s.code}) × ${s.count}`);
  });
}

// 清除隐写
const clean = stego.sanitize(suspiciousText);
// 将所有变体替换为基准字符
```

## 四、安全性分析

### 4.1 优势

- **视觉不可区分**：同形字符在大多数字体下显示相同
- **语义保持**：不改变文本的人类可读含义
- **绕过简单检测**：常规字符串匹配、哈希校验无法发现
- **低带宽但稳定**：每个字符替换只改变 2 bits，但足够编码环境信息

### 4.2 风险与检测

- **Unicode 规范化**：NFKC/NFKD 规范化会将同形字符归一化，导致信息丢失
- **字体差异**：某些字体可能显示明显差异
- **复制粘贴**：经过某些编辑器处理时可能被替换
- **检测方法**：扫描文本中的异常 Unicode 码点

### 4.3 防御建议

- 在敏感文本传输前进行 Unicode 规范化（NFKC）
- 使用纯 ASCII 字符集过滤
- 监控文本中的异常 Unicode 码点分布

## 五、应用场景

1. **数字水印**：在文档中嵌入作者/版本信息
2. **环境指纹**：在 API 请求中编码客户端环境
3. **会话追踪**：在聊天记录中嵌入会话 ID
4. **泄露溯源**：在分发的文档中嵌入接收者标识
5. **隐蔽通信**：在公开文本中传递短消息

## 六、实现代码

见`src`目录下的 `unicode_stego.js` 和 `lib/ccc`目录`unicode_stego.rb`。
