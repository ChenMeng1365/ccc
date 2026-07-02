# frozen_string_literal: true

# Claude Code 后门信息隐藏算法 - Ruby 实现
#
# 原理：通过系统提示词中的日期格式和 Unicode 撇号变体编码环境信息
#
# 编码规则：
#   日期格式：
#     - 短横线 "2026-06-30" => 非中国时区
#     - 斜杠   "2026/06/30" => 中国时区 (Asia/Shanghai, Asia/Urumqi)
#
#   撇号字符（编码 2 bits）：
#     - U+0027 "'"  => 未命中域名，未命中关键词 (00)
#     - U+2019 "'"  => 命中中国域名，未命中关键词 (01)
#     - U+02BC "'"  => 未命中域名，命中AI实验室关键词 (10)
#     - U+02B9 "′"  => 两者都命中 (11)

require 'date'
require 'base64'

class StegoEncoder
  # Unicode 撇号变体映射
  APOSTROPHE_VARIANTS = {
    standard:  "\u0027",   # '  标准 ASCII 撇号
    right:     "\u2019",   # '  右单引号
    modifier:  "\u02BC",   # '  修饰字母撇号
    prime:     "\u02B9",   # ′  修饰字母上标号
  }.freeze

  # 中国时区列表
  CHINA_TIMEZONES = ["Asia/Shanghai", "Asia/Urumqi"].freeze

  # 域名黑名单（部分示例）
  DOMAIN_BLACKLIST = [
    "cn", "sankuai.com", "netease.com", "163.com", "baidu.com",
    "alibaba-inc.com", "alipay.com", "antgroup-inc.cn", "kuaishou.com",
    "bytedance.net", "xiaohongshu.com", "jd.com", "bilibili.co",
    "iflytek.com", "stepfun-inc.com", "aliyuncs.com", "moonshot.ai",
    "deepseek", "minimax", "zhipu", "bigmodel", "baichuan", "01ai",
    "dashscope", "volces", "xaminim"
  ].freeze

  # AI 实验室关键词
  AI_LAB_KEYWORDS = [
    "deepseek", "moonshot", "minimax", "xaminim", "zhipu",
    "bigmodel", "baichuan", "stepfun", "01ai", "dashscope", "volces"
  ].freeze

  # XOR 混淆密钥（Claude Code 使用 91）
  XOR_KEY = 91

  attr_reader :china_timezones, :domain_blacklist, :ai_lab_keywords

  def initialize
    @china_timezones = CHINA_TIMEZONES.dup
    @domain_blacklist = DOMAIN_BLACKLIST.dup
    @ai_lab_keywords = AI_LAB_KEYWORDS.dup
  end

  # 检测时区是否为中国时区
  # @param [String] tz 时区字符串，如 "Asia/Shanghai"
  # @return [Boolean]
  def china_tz?(tz = nil)
    tz ||= ENV['TZ'] || Time.now.zone
    @china_timezones.any? { |c| tz.to_s.include?(c) }
  end

  # 检测代理 URL 是否命中黑名单
  # @param [String, nil] proxy_url 代理 URL
  # @return [Hash] { domain_hit: Boolean, keyword_hit: Boolean }
  def detect_proxy(proxy_url)
    return { domain_hit: false, keyword_hit: false } if proxy_url.nil? || proxy_url.empty?

    lower_url = proxy_url.downcase

    domain_hit = @domain_blacklist.any? do |domain|
      if domain == "cn"
        lower_url.include?(".cn") || lower_url.include?("cn-")
      else
        lower_url.include?(domain)
      end
    end

    keyword_hit = @ai_lab_keywords.any? { |kw| lower_url.include?(kw) }

    { domain_hit: domain_hit, keyword_hit: keyword_hit }
  end

  # 编码：根据环境信息生成隐写日期字符串
  # @param [Boolean] is_china_tz 是否中国时区
  # @param [Boolean] domain_hit 是否命中域名黑名单
  # @param [Boolean] keyword_hit 是否命中AI实验室关键词
  # @param [Date, Time] date 可选，指定日期，默认当前
  # @return [String] 编码后的日期字符串
  def encode(is_china_tz:, domain_hit:, keyword_hit:, date: Date.today)
    separator = is_china_tz ? "/" : "-"
    date_str = date.strftime("%Y#{separator}%m#{separator}%d")

    # 撇号编码域名/关键词信息（2 bits）
    apostrophe = case [domain_hit, keyword_hit]
                 when [false, false] then APOSTROPHE_VARIANTS[:standard]   # 00
                 when [true, false]  then APOSTROPHE_VARIANTS[:right]       # 01
                 when [false, true]  then APOSTROPHE_VARIANTS[:modifier]   # 10
                 when [true, true]   then APOSTROPHE_VARIANTS[:prime]      # 11
                 end

    # 构建系统提示词片段
    "Today#{apostrophe}s date is #{date_str}."
  end

  # 自动检测环境并编码
  # @param [String, nil] proxy_url 代理 URL
  # @param [Date, Time] date 可选日期
  # @return [String] 编码后的系统提示词片段
  def auto_encode(proxy_url: nil, date: Date.today)
    is_china = china_tz?
    proxy_info = detect_proxy(proxy_url)
    encode(
      is_china_tz: is_china,
      domain_hit: proxy_info[:domain_hit],
      keyword_hit: proxy_info[:keyword_hit],
      date: date
    )
  end

  # 解码：从系统提示词中提取隐藏信息
  # @param [String] prompt_text 系统提示词文本
  # @return [Hash, nil] 解码后的信息
  def decode(prompt_text)
    return nil if prompt_text.nil? || prompt_text.empty?

    # 提取日期格式
    date_match = prompt_text.match(/(\d{4})\/(\d{2})\/(\d{2})/)
    if date_match
      is_china_tz = true
      date_str = date_match[0]
    else
      date_match = prompt_text.match(/(\d{4})-(\d{2})-(\d{2})/)
      return nil unless date_match
      is_china_tz = false
      date_str = date_match[0]
    end

    # 提取撇号变体（查找 Today 后面的字符）
    today_match = prompt_text.match(/Today(.)s date/)
    return nil unless today_match

    apostrophe = today_match[1]
    code_point = apostrophe.ord

    domain_hit, keyword_hit = case code_point
                              when 0x0027 then [false, false]
                              when 0x2019 then [true, false]
                              when 0x02BC then [false, true]
                              when 0x02B9 then [true, true]
                              else return nil
                              end

    {
      is_china_tz: is_china_tz,
      domain_hit: domain_hit,
      keyword_hit: keyword_hit,
      date: date_str,
      apostrophe: "U+#{code_point.to_s(16).upcase.rjust(4, '0')}",
      raw: prompt_text
    }
  end

  # 混淆：XOR 编码（模拟 Claude Code 的域名列表混淆）
  # @param [String] data 原始数据
  # @param [Integer] key XOR 密钥
  # @return [String] XOR 编码后的 Base64
  def xor_obfuscate(data, key = XOR_KEY)
    obfuscated = data.bytes.map { |b| b ^ key }.pack('C*')
    Base64.strict_encode64(obfuscated)
  end

  # 反混淆：XOR 解码
  # @param [String] base64_data Base64 编码的混淆数据
  # @param [Integer] key XOR 密钥
  # @return [String] 原始数据
  def xor_deobfuscate(base64_data, key = XOR_KEY)
    obfuscated = Base64.strict_decode64(base64_data)
    obfuscated.bytes.map { |b| b ^ key }.pack('C*')
  end

  # 批量编码演示
  # @return [Array<Hash>] 所有状态的编码结果
  def demo_all_states
    states = [
      { name: "非中国/未命中", tz: false, dom: false, kw: false },
      { name: "非中国/命中域名", tz: false, dom: true, kw: false },
      { name: "非中国/命中关键词", tz: false, dom: false, kw: true },
      { name: "非中国/两者命中", tz: false, dom: true, kw: true },
      { name: "中国/未命中", tz: true, dom: false, kw: false },
      { name: "中国/命中域名", tz: true, dom: true, kw: false },
      { name: "中国/命中关键词", tz: true, dom: false, kw: true },
      { name: "中国/两者命中", tz: true, dom: true, kw: true },
    ]

    states.map do |s|
      encoded = encode(is_china_tz: s[:tz], domain_hit: s[:dom], keyword_hit: s[:kw])
      decoded = decode(encoded)
      {
        state: s[:name],
        encoded: encoded,
        decoded: decoded
      }
    end
  end
end
