/**
 * Unicode 隐写编码方案 - JavaScript 实现
 * 
 * 基于 Unicode 同形字符（homoglyphs）的文本隐写技术
 * 利用视觉上相同但编码不同的 Unicode 字符来嵌入隐藏信息
 * 
 * 5 个通道 × 2 bits = 10 bits 编码空间
 */

class UnicodeStego {
  constructor() {
    // 通道定义：每个通道包含 4 个同形字符（2 bits）
    this.CHANNELS = {
      APOSTROPHE: {
        name: "撇号",
        bits: 2,
        chars: [
          { code: 0x0027, char: "'", name: "标准 ASCII 撇号" },      // 00
          { code: 0x2019, char: "'", name: "右单引号" },             // 01
          { code: 0x02BC, char: "'", name: "修饰字母撇号" },         // 10
          { code: 0x02B9, char: "′", name: "修饰字母上标号" },        // 11
        ],
        regex: /['’ʼʹ]/g,
      },
      HYPHEN: {
        name: "短横线",
        bits: 2,
        chars: [
          { code: 0x002D, char: "-", name: "标准连字符" },             // 00
          { code: 0x2010, char: "‐", name: "连字符" },               // 01
          { code: 0x2011, char: "‑", name: "非断连字符" },            // 10
          { code: 0x2212, char: "−", name: "减号" },                 // 11
        ],
        regex: /[-‐‑−]/g,
      },
      SPACE: {
        name: "空格",
        bits: 2,
        chars: [
          { code: 0x0020, char: " ", name: "标准空格" },              // 00
          { code: 0x00A0, char: " ", name: "不间断空格" },       // 01
          { code: 0x2002, char: " ", name: "En 空格" },         // 10
          { code: 0x2003, char: " ", name: "Em 空格" },         // 11
        ],
        regex: /[    ]/g,
      },
      PERIOD: {
        name: "句号",
        bits: 2,
        chars: [
          { code: 0x002E, char: ".", name: "标准句点" },              // 00
          { code: 0x2024, char: "․", name: "一点前导" },             // 01
          { code: 0x06D4, char: "۔", name: "阿拉伯句号" },           // 10
          { code: 0x3002, char: "。", name: "中文句号" },             // 11
        ],
        regex: /[.․۔。]/g,
      },
      COLON: {
        name: "冒号",
        bits: 2,
        chars: [
          { code: 0x003A, char: ":", name: "标准冒号" },              // 00
          { code: 0x2236, char: "∶", name: "比例符号" },             // 01
          { code: 0x02F8, char: "˸", name: "修饰字母冒号" },         // 10
          { code: 0xA789, char: "꞉", name: "拉丁修饰冒号" },          // 11
        ],
        regex: /[:∶˸꞉]/g,
      },
    };

    // 通道优先级（从高到低）
    this.CHANNEL_ORDER = [
      "APOSTROPHE", "HYPHEN", "SPACE", "PERIOD", "COLON"
    ];
  }

  /**
   * 获取通道的编码值（0-3）
   * @param {string} channelName - 通道名称
   * @param {string} char - 字符
   * @returns {number} 编码值（0-3），-1 表示未找到
   */
  getChannelValue(channelName, char) {
    const channel = this.CHANNELS[channelName];
    if (!channel) return -1;
    const cp = char.codePointAt(0);
    for (let i = 0; i < channel.chars.length; i++) {
      if (channel.chars[i].code === cp) {
        return i;
      }
    }
    return -1;
  }

  /**
   * 获取通道的字符
   * @param {string} channelName - 通道名称
   * @param {number} value - 编码值（0-3）
   * @returns {string} 对应的字符
   */
  getChannelChar(channelName, value) {
    const channel = this.CHANNELS[channelName];
    if (!channel || value < 0 || value > 3) return null;
    return String.fromCodePoint(channel.chars[value].code);
  }

  /**
   * 统计文本中各通道可用字符数量
   * @param {string} text - 明文文本
   * @returns {Object} 各通道可用数量
   */
  countAvailableSlots(text) {
    const counts = {};
    for (const name of this.CHANNEL_ORDER) {
      const channel = this.CHANNELS[name];
      const matches = text.match(channel.regex);
      counts[name] = matches ? matches.length : 0;
    }
    return counts;
  }

  /**
   * 计算文本的最大编码容量（bits）
   * @param {string} text - 明文文本
   * @returns {number} 最大可编码位数
   */
  getCapacity(text) {
    const counts = this.countAvailableSlots(text);
    let totalBits = 0;
    for (const name of this.CHANNEL_ORDER) {
      totalBits += counts[name] * this.CHANNELS[name].bits;
    }
    return totalBits;
  }

  /**
   * 将数据编码为通道序列
   * @param {number} data - 待编码数据（整数）
   * @param {number} bits - 数据位数
   * @returns {number[]} 各通道的编码值序列
   */
  dataToChannelValues(data, bits) {
    const values = [];
    let remaining = data;
    for (let i = 0; i < Math.ceil(bits / 2); i++) {
      values.push(remaining & 0b11);
      remaining >>= 2;
    }
    return values;
  }

  /**
   * 将通道序列解码为数据
   * @param {number[]} values - 各通道的编码值序列
   * @returns {number} 解码后的数据
   */
  channelValuesToData(values) {
    let data = 0;
    for (let i = values.length - 1; i >= 0; i--) {
      data = (data << 2) | values[i];
    }
    return data;
  }

  /**
   * 编码：将数据嵌入文本
   * @param {string} text - 明文文本
   * @param {number} data - 待编码数据（整数）
   * @param {number} bits - 数据位数（默认自动计算）
   * @returns {Object} { stegoText: string, usedChannels: Object, data: number }
   */
  encode(text, data, bits = null) {
    if (bits === null) {
      bits = Math.floor(Math.log2(data)) + 1;
    }

    const capacity = this.getCapacity(text);
    if (bits > capacity) {
      throw new Error(`数据需要 ${bits} bits，但文本容量只有 ${capacity} bits`);
    }

    const values = this.dataToChannelValues(data, bits);
    const usedChannels = {};
    let valueIndex = 0;
    let result = text;

    // 按优先级使用通道
    for (const channelName of this.CHANNEL_ORDER) {
      if (valueIndex >= values.length) break;

      const channel = this.CHANNELS[channelName];
      const regex = new RegExp(channel.regex.source, "g");
      let matchCount = 0;

      result = result.replace(regex, (match) => {
        if (valueIndex >= values.length) return match;

        const value = values[valueIndex];
        const newChar = this.getChannelChar(channelName, value);

        if (!usedChannels[channelName]) {
          usedChannels[channelName] = { count: 0, values: [] };
        }
        usedChannels[channelName].count++;
        usedChannels[channelName].values.push(value);

        valueIndex++;
        matchCount++;
        return newChar;
      });
    }

    return {
      stegoText: result,
      usedChannels,
      data,
      bits,
      capacity,
    };
  }

  /**
   * 解码：从文本中提取数据
   * @param {string} stegoText - 隐写文本
   * @param {number} bits - 数据位数（默认使用最大容量）
   * @returns {Object} { data: number, usedChannels: Object, bits: number }
   */
  decode(stegoText, bits = null) {
    const values = [];
    const usedChannels = {};

    // 按优先级扫描通道
    for (const channelName of this.CHANNEL_ORDER) {
      const channel = this.CHANNELS[channelName];
      const regex = new RegExp(channel.regex.source, "g");
      let match;

      while ((match = regex.exec(stegoText)) !== null) {
        const char = match[0];
        const value = this.getChannelValue(channelName, char);

        if (value !== -1) {
          values.push(value);

          if (!usedChannels[channelName]) {
            usedChannels[channelName] = { count: 0, values: [] };
          }
          usedChannels[channelName].count++;
          usedChannels[channelName].values.push(value);
        }
      }
    }

    if (bits === null) {
      bits = values.length * 2;
    }

    // 只取需要的位数
    const neededValues = Math.ceil(bits / 2);
    const actualValues = values.slice(0, neededValues);
    const data = this.channelValuesToData(actualValues);

    return {
      data,
      usedChannels,
      bits: Math.min(bits, values.length * 2),
      allValues: values,
    };
  }

  /**
   * 检测文本是否包含隐写信息
   * @param {string} text - 待检测文本
   * @returns {Object} 检测结果
   */
  detect(text) {
    const suspicious = [];

    for (const [name, channel] of Object.entries(this.CHANNELS)) {
      for (const charInfo of channel.chars) {
        if (charInfo.code === channel.chars[0].code) continue; // 跳过基准字符

        const regex = new RegExp(String.fromCodePoint(charInfo.code), "g");
        const matches = text.match(regex);
        if (matches) {
          suspicious.push({
            channel: name,
            char: String.fromCodePoint(charInfo.code),
            code: `U+${charInfo.code.toString(16).toUpperCase().padStart(4, "0")}`,
            name: charInfo.name,
            count: matches.length,
          });
        }
      }
    }

    return {
      hasStego: suspicious.length > 0,
      suspicious,
      summary: suspicious.length > 0 
        ? `发现 ${suspicious.length} 种可疑字符，可能包含隐写信息`
        : "未发现可疑 Unicode 字符",
    };
  }

  /**
   * 防御：清除文本中的隐写信息（Unicode 规范化）
   * @param {string} text - 待清理文本
   * @returns {string} 清理后的纯文本
   */
  sanitize(text) {
    // 将所有变体替换为基准字符
    let result = text;
    for (const channel of Object.values(this.CHANNELS)) {
      for (let i = 1; i < channel.chars.length; i++) {
        const regex = new RegExp(String.fromCodePoint(channel.chars[i].code), "g");
        result = result.replace(regex, String.fromCodePoint(channel.chars[0].code));
      }
    }
    return result;
  }

  /**
   * 生成环境指纹（模拟 Claude Code 的用法）
   * @param {Object} env - 环境信息
   * @returns {number} 10-bit 环境指纹
   */
  generateFingerprint(env = {}) {
    let fingerprint = 0;

    // bit 0: 是否中国时区
    if (env.timeZone === "Asia/Shanghai" || env.timeZone === "Asia/Urumqi") {
      fingerprint |= 0b1;
    }

    // bit 1-2: 代理类型（0=无, 1=中国域名, 2=AI实验室, 3=两者）
    let proxyType = 0;
    if (env.isChinaDomain) proxyType |= 0b01;
    if (env.isAILab) proxyType |= 0b10;
    fingerprint |= (proxyType & 0b11) << 1;

    // bit 3: 是否使用代理
    if (env.hasProxy) fingerprint |= 0b1 << 3;

    // bit 4-5: 操作系统类型（0=未知, 1=Windows, 2=macOS, 3=Linux）
    const osMap = { windows: 1, darwin: 2, linux: 3 };
    const osType = osMap[env.platform?.toLowerCase()] || 0;
    fingerprint |= (osType & 0b11) << 4;

    // bit 6-7: 语言区域（0=未知, 1=zh-CN, 2=en-US, 3=其他）
    const langMap = { "zh-cn": 1, "en-us": 2 };
    const langType = langMap[env.locale?.toLowerCase()] || 0;
    fingerprint |= (langType & 0b11) << 6;

    // bit 8-9: 保留/随机（用于水印区分）
    fingerprint |= (Math.floor(Math.random() * 4) & 0b11) << 8;

    return fingerprint & 0x3FF; // 确保 10 bits
  }

  /**
   * 解析环境指纹
   * @param {number} fingerprint - 10-bit 指纹
   * @returns {Object} 解析后的环境信息
   */
  parseFingerprint(fingerprint) {
    return {
      isChinaTZ: !!(fingerprint & 0b1),
      proxyType: (fingerprint >> 1) & 0b11,
      hasProxy: !!((fingerprint >> 3) & 0b1),
      osType: (fingerprint >> 4) & 0b11,
      localeType: (fingerprint >> 6) & 0b11,
      reserved: (fingerprint >> 8) & 0b11,
    };
  }
}

module.exports = { UnicodeStego };
