# frozen_string_literal: true

# Unicode 隐写编码方案 - Ruby 实现
#
# 基于 Unicode 同形字符（homoglyphs）的文本隐写技术
# 利用视觉上相同但编码不同的 Unicode 字符来嵌入隐藏信息
#
# 5 个通道 x 2 bits = 10 bits 编码空间

require 'base64'

class UnicodeStego
  # 通道定义：每个通道包含 4 个同形字符（2 bits）
  CHANNELS = {
    apostrophe: {
      name: "撇号",
      bits: 2,
      chars: [
        { code: 0x0027, char: "'", name: "标准 ASCII 撇号" },      # 00
        { code: 0x2019, char: "\u2019", name: "右单引号" },             # 01
        { code: 0x02BC, char: "\u02BC", name: "修饰字母撇号" },         # 10
        { code: 0x02B9, char: "\u02B9", name: "修饰字母上标号" },        # 11
      ],
      regex: /['\u2019\u02BC\u02B9]/,
    },
    hyphen: {
      name: "短横线",
      bits: 2,
      chars: [
        { code: 0x002D, char: "-", name: "标准连字符" },             # 00
        { code: 0x2010, char: "\u2010", name: "连字符" },               # 01
        { code: 0x2011, char: "\u2011", name: "非断连字符" },            # 10
        { code: 0x2212, char: "\u2212", name: "减号" },                 # 11
      ],
      regex: /[-\u2010\u2011\u2212]/,
    },
    space: {
      name: "空格",
      bits: 2,
      chars: [
        { code: 0x0020, char: " ", name: "标准空格" },              # 00
        { code: 0x00A0, char: "\u00A0", name: "不间断空格" },       # 01
        { code: 0x2002, char: "\u2002", name: "En 空格" },         # 10
        { code: 0x2003, char: "\u2003", name: "Em 空格" },         # 11
      ],
      regex: /[ \u00A0\u2002\u2003]/,
    },
    period: {
      name: "句号",
      bits: 2,
      chars: [
        { code: 0x002E, char: ".", name: "标准句点" },              # 00
        { code: 0x2024, char: "\u2024", name: "一点前导" },             # 01
        { code: 0x06D4, char: "\u06D4", name: "阿拉伯句号" },           # 10
        { code: 0x3002, char: "\u3002", name: "中文句号" },             # 11
      ],
      regex: /[.\u2024\u06D4\u3002]/,
    },
    colon: {
      name: "冒号",
      bits: 2,
      chars: [
        { code: 0x003A, char: ":", name: "标准冒号" },              # 00
        { code: 0x2236, char: "\u2236", name: "比例符号" },             # 01
        { code: 0x02F8, char: "\u02F8", name: "修饰字母冒号" },         # 10
        { code: 0xA789, char: "\uA789", name: "拉丁修饰冒号" },          # 11
      ],
      regex: /[:\u2236\u02F8\uA789]/,
    },
  }.freeze

  # 通道优先级（从高到低）
  CHANNEL_ORDER = [:apostrophe, :hyphen, :space, :period, :colon].freeze

  attr_reader :channels, :channel_order

  def initialize
    @channels = CHANNELS.dup
    @channel_order = CHANNEL_ORDER.dup
  end

  # 获取通道的编码值（0-3）
  # @param [Symbol] channel_name 通道名称
  # @param [String] char 字符
  # @return [Integer] 编码值（0-3），-1 表示未找到
  def get_channel_value(channel_name, char)
    channel = @channels[channel_name]
    return -1 unless channel

    cp = char.ord
    channel[:chars].each_with_index do |c, i|
      return i if c[:code] == cp
    end
    -1
  end

  # 获取通道的字符
  # @param [Symbol] channel_name 通道名称
  # @param [Integer] value 编码值（0-3）
  # @return [String, nil] 对应的字符
  def get_channel_char(channel_name, value)
    channel = @channels[channel_name]
    return nil unless channel && value >= 0 && value <= 3
    channel[:chars][value][:code].chr(Encoding::UTF_8)
  end

  # 统计文本中各通道可用字符数量
  # @param [String] text 明文文本
  # @return [Hash] 各通道可用数量
  def count_available_slots(text)
    counts = {}
    @channel_order.each do |name|
      channel = @channels[name]
      regex = channel[:regex]
      matches = text.scan(regex)
      counts[name] = matches.length
    end
    counts
  end

  # 计算文本的最大编码容量（bits）
  # @param [String] text 明文文本
  # @return [Integer] 最大可编码位数
  def get_capacity(text)
    counts = count_available_slots(text)
    total_bits = 0
    @channel_order.each do |name|
      total_bits += counts[name] * @channels[name][:bits]
    end
    total_bits
  end

  # 将数据编码为通道序列
  # @param [Integer] data 待编码数据
  # @param [Integer] bits 数据位数
  # @return [Array<Integer>] 各通道的编码值序列
  def data_to_channel_values(data, bits)
    values = []
    remaining = data
    (bits.to_f / 2).ceil.times do
      values << (remaining & 0b11)
      remaining >>= 2
    end
    values
  end

  # 将通道序列解码为数据
  # @param [Array<Integer>] values 各通道的编码值序列
  # @return [Integer] 解码后的数据
  def channel_values_to_data(values)
    data = 0
    values.reverse_each do |v|
      data = (data << 2) | v
    end
    data
  end

  # 编码：将数据嵌入文本
  # @param [String] text 明文文本
  # @param [Integer] data 待编码数据
  # @param [Integer, nil] bits 数据位数（默认自动计算）
  # @return [Hash] 编码结果
  def encode(text, data, bits = nil)
    bits ||= (Math.log2(data).floor + 1)

    capacity = get_capacity(text)
    raise "数据需要 #{bits} bits，但文本容量只有 #{capacity} bits" if bits > capacity

    values = data_to_channel_values(data, bits)
    used_channels = {}
    value_index = 0
    result = text.dup

    # 按优先级使用通道
    @channel_order.each do |channel_name|
      break if value_index >= values.length

      channel = @channels[channel_name]
      regex = channel[:regex]
      match_count = 0

      result.gsub!(regex) do |match|
        break match if value_index >= values.length

        value = values[value_index]
        new_char = get_channel_char(channel_name, value)

        used_channels[channel_name] ||= { count: 0, values: [] }
        used_channels[channel_name][:count] += 1
        used_channels[channel_name][:values] << value

        value_index += 1
        match_count += 1
        new_char
      end
    end

    {
      stego_text: result,
      used_channels: used_channels,
      data: data,
      bits: bits,
      capacity: capacity,
    }
  end

  # 解码：从文本中提取数据
  # @param [String] stego_text 隐写文本
  # @param [Integer, nil] bits 数据位数（默认使用最大容量）
  # @return [Hash] 解码结果
  def decode(stego_text, bits = nil)
    values = []
    used_channels = {}

    # 按优先级扫描通道
    @channel_order.each do |channel_name|
      channel = @channels[channel_name]
      regex = channel[:regex]

      stego_text.scan(regex) do |match|
        char = match.is_a?(Array) ? match[0] : match
        value = get_channel_value(channel_name, char)

        if value != -1
          values << value

          used_channels[channel_name] ||= { count: 0, values: [] }
          used_channels[channel_name][:count] += 1
          used_channels[channel_name][:values] << value
        end
      end
    end

    bits ||= values.length * 2

    # 只取需要的位数
    needed_values = (bits.to_f / 2).ceil
    actual_values = values.take(needed_values)
    data = channel_values_to_data(actual_values)

    {
      data: data,
      used_channels: used_channels,
      bits: [bits, values.length * 2].min,
      all_values: values,
    }
  end

  # 检测文本是否包含隐写信息
  # @param [String] text 待检测文本
  # @return [Hash] 检测结果
  def detect(text)
    suspicious = []

    @channels.each do |name, channel|
      channel[:chars].each_with_index do |char_info, i|
        next if i == 0 # 跳过基准字符

        regex = Regexp.new(Regexp.escape(char_info[:code].chr(Encoding::UTF_8)))
        matches = text.scan(regex)
        next if matches.empty?

        suspicious << {
          channel: name,
          char: char_info[:code].chr(Encoding::UTF_8),
          code: "U+#{char_info[:code].to_s(16).upcase.rjust(4, '0')}",
          name: char_info[:name],
          count: matches.length,
        }
      end
    end

    {
      has_stego: !suspicious.empty?,
      suspicious: suspicious,
      summary: suspicious.empty? ? "未发现可疑 Unicode 字符" : "发现 #{suspicious.length} 种可疑字符，可能包含隐写信息",
    }
  end

  # 防御：清除文本中的隐写信息
  # @param [String] text 待清理文本
  # @return [String] 清理后的纯文本
  def sanitize(text)
    result = text.dup
    @channels.each do |_name, channel|
      channel[:chars].each_with_index do |char_info, i|
        next if i == 0 # 跳过基准字符
        result.gsub!(char_info[:code].chr(Encoding::UTF_8), channel[:chars][0][:code].chr(Encoding::UTF_8))
      end
    end
    result
  end

  # 生成环境指纹（模拟 Claude Code 的用法）
  # @param [Hash] env 环境信息
  # @return [Integer] 10-bit 环境指纹
  def generate_fingerprint(env = {})
    fingerprint = 0

    # bit 0: 是否中国时区
    if env[:time_zone] == "Asia/Shanghai" || env[:time_zone] == "Asia/Urumqi"
      fingerprint |= 0b1
    end

    # bit 1-2: 代理类型
    proxy_type = 0
    proxy_type |= 0b01 if env[:is_china_domain]
    proxy_type |= 0b10 if env[:is_ai_lab]
    fingerprint |= (proxy_type & 0b11) << 1

    # bit 3: 是否使用代理
    fingerprint |= 0b1 << 3 if env[:has_proxy]

    # bit 4-5: 操作系统类型
    os_map = { "windows" => 1, "darwin" => 2, "linux" => 3 }
    os_type = os_map[env[:platform]&.downcase] || 0
    fingerprint |= (os_type & 0b11) << 4

    # bit 6-7: 语言区域
    lang_map = { "zh-cn" => 1, "en-us" => 2 }
    lang_type = lang_map[env[:locale]&.downcase] || 0
    fingerprint |= (lang_type & 0b11) << 6

    # bit 8-9: 保留/随机
    fingerprint |= (rand(4) & 0b11) << 8

    fingerprint & 0x3FF # 确保 10 bits
  end

  # 解析环境指纹
  # @param [Integer] fingerprint 10-bit 指纹
  # @return [Hash] 解析后的环境信息
  def parse_fingerprint(fingerprint)
    {
      is_china_tz: (fingerprint & 0b1) != 0,
      proxy_type: (fingerprint >> 1) & 0b11,
      has_proxy: ((fingerprint >> 3) & 0b1) != 0,
      os_type: (fingerprint >> 4) & 0b11,
      locale_type: (fingerprint >> 6) & 0b11,
      reserved: (fingerprint >> 8) & 0b11,
    }
  end
end
