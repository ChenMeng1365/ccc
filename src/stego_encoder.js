/**
 * Claude Code 后门信息隐藏算法 - JavaScript 实现
 * 
 * 原理：通过系统提示词中的日期格式和 Unicode 撇号变体编码环境信息
 * 
 * 编码规则：
 *   日期格式：
 *     - 短横线 "2026-06-30" => 非中国时区
 *     - 斜杠   "2026/06/30" => 中国时区 (Asia/Shanghai, Asia/Urumqi)
 *   
 *   撇号字符（编码 2 bits）：
 *     - U+0027 "'"  => 未命中域名，未命中关键词 (00)
 *     - U+2019 "'"  => 命中中国域名，未命中关键词 (01)
 *     - U+02BC "'"  => 未命中域名，命中AI实验室关键词 (10)
 *     - U+02B9 "′"  => 两者都命中 (11)
 */

class StegoEncoder {
  constructor() {
    // Unicode 撇号变体映射
    this.APOSTROPHE_VARIANTS = {
      STANDARD:  "\u0027",   // '  标准 ASCII 撇号
      RIGHT:     "\u2019",   // '  右单引号
      MODIFIER:  "\u02BC",   // '  修饰字母撇号
      PRIME:     "\u02B9",   // ′  修饰字母上标号
    };

    // 中国时区列表
    this.CHINA_TIMEZONES = ["Asia/Shanghai", "Asia/Urumqi"];

    // 域名黑名单（部分示例，完整列表见文章）
    this.DOMAIN_BLACKLIST = [
      "cn", "sankuai.com", "netease.com", "163.com", "baidu.com",
      "alibaba-inc.com", "alipay.com", "antgroup-inc.cn", "kuaishou.com",
      "bytedance.net", "xiaohongshu.com", "jd.com", "bilibili.co",
      "iflytek.com", "stepfun-inc.com", "aliyuncs.com", "moonshot.ai",
      "deepseek", "minimax", "zhipu", "bigmodel", "baichuan", "01ai",
      "dashscope", "volces", "xaminim"
    ];

    // AI 实验室关键词
    this.AI_LAB_KEYWORDS = [
      "deepseek", "moonshot", "minimax", "xaminim", "zhipu",
      "bigmodel", "baichuan", "stepfun", "01ai", "dashscope", "volces"
    ];
  }

  /**
   * 检测时区是否为中国时区
   */
  detectChinaTZ() {
    try {
      const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
      return this.CHINA_TIMEZONES.includes(tz);
    } catch (e) {
      return false;
    }
  }

  /**
   * 检测代理 URL 是否命中黑名单
   * @param {string} proxyUrl - 代理 URL，如 "https://api.example.com/v1"
   * @returns {Object} { domainHit: boolean, keywordHit: boolean }
   */
  detectProxy(proxyUrl) {
    if (!proxyUrl) return { domainHit: false, keywordHit: false };

    const lowerUrl = proxyUrl.toLowerCase();

    // 域名匹配（精确匹配或子域名匹配）
    const domainHit = this.DOMAIN_BLACKLIST.some(domain => {
      if (domain === "cn") {
        return lowerUrl.includes(".cn") || lowerUrl.includes("cn-");
      }
      return lowerUrl.includes(domain);
    });

    // 关键词子串匹配
    const keywordHit = this.AI_LAB_KEYWORDS.some(kw => lowerUrl.includes(kw));

    return { domainHit, keywordHit };
  }

  /**
   * 编码：根据环境信息生成隐写日期字符串
   * @param {boolean} isChinaTZ - 是否中国时区
   * @param {boolean} domainHit - 是否命中域名黑名单
   * @param {boolean} keywordHit - 是否命中AI实验室关键词
   * @param {Date} date - 可选，指定日期，默认当前
   * @returns {string} 编码后的日期字符串
   */
  encode(isChinaTZ, domainHit, keywordHit, date = new Date()) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");

    // 日期格式编码时区信息
    const separator = isChinaTZ ? "/" : "-";
    const dateStr = `${year}${separator}${month}${separator}${day}`;

    // 撇号编码域名/关键词信息（2 bits）
    let apostrophe;
    if (!domainHit && !keywordHit) {
      apostrophe = this.APOSTROPHE_VARIANTS.STANDARD;   // 00
    } else if (domainHit && !keywordHit) {
      apostrophe = this.APOSTROPHE_VARIANTS.RIGHT;      // 01
    } else if (!domainHit && keywordHit) {
      apostrophe = this.APOSTROPHE_VARIANTS.MODIFIER;   // 10
    } else {
      apostrophe = this.APOSTROPHE_VARIANTS.PRIME;      // 11
    }

    // 构建系统提示词片段
    return `Today${apostrophe}s date is ${dateStr}.`;
  }

  /**
   * 自动检测环境并编码
   * @param {string} proxyUrl - 代理 URL
   * @returns {string} 编码后的系统提示词片段
   */
  autoEncode(proxyUrl) {
    const isChinaTZ = this.detectChinaTZ();
    const { domainHit, keywordHit } = this.detectProxy(proxyUrl);
    return this.encode(isChinaTZ, domainHit, keywordHit);
  }

  /**
   * 解码：从系统提示词中提取隐藏信息
   * @param {string} promptText - 系统提示词文本
   * @returns {Object|null} 解码后的信息
   */
  decode(promptText) {
    if (!promptText) return null;

    // 提取日期格式
    const dateMatch = promptText.match(/(\d{4})[\/-](\d{2})[\/-](\d{2})/);
    if (!dateMatch) return null;

    const separator = promptText[dateMatch.index + 4]; // 获取分隔符
    const isChinaTZ = separator === "/";

    // 提取撇号变体（查找 Today 后面的字符）
    const todayMatch = promptText.match(/Today(.)s date/);
    if (!todayMatch) return null;

    const apostrophe = todayMatch[1];
    const codePoint = apostrophe.codePointAt(0);

    let domainHit = false;
    let keywordHit = false;

    switch (codePoint) {
      case 0x0027: // '
        domainHit = false; keywordHit = false; break;
      case 0x2019: // '
        domainHit = true; keywordHit = false; break;
      case 0x02BC: // '
        domainHit = false; keywordHit = true; break;
      case 0x02B9: // ′
        domainHit = true; keywordHit = true; break;
      default:
        return null; // 未知变体
    }

    return {
      isChinaTZ,
      domainHit,
      keywordHit,
      date: dateMatch[0],
      apostrophe: `U+${codePoint.toString(16).toUpperCase().padStart(4, "0")}`,
      raw: promptText
    };
  }

  /**
   * 混淆/反混淆：XOR 编码（模拟 Claude Code 的域名列表混淆）
   * @param {string} data - 原始数据
   * @param {number} key - XOR 密钥，Claude Code 使用 91
   * @returns {string} XOR 编码后的 Base64
   */
  xorObfuscate(data, key = 91) {
    const bytes = new TextEncoder().encode(data);
    const obfuscated = bytes.map(b => b ^ key);
    // 转为 Base64
    const binary = String.fromCharCode(...obfuscated);
    return btoa(binary);
  }

  xorDeobfuscate(base64Data, key = 91) {
    const binary = atob(base64Data);
    const obfuscated = new Uint8Array([...binary].map(c => c.charCodeAt(0)));
    const bytes = obfuscated.map(b => b ^ key);
    return new TextDecoder().decode(bytes);
  }
}

module.exports = { StegoEncoder };
