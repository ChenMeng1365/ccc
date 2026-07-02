# frozen_string_literal: true

require_relative "../../lib/ccc/unicode_stego"

# === Unicode 隐写编码方案 — Ruby 演示 ===

stego = UnicodeStego.new

puts "=== Unicode 隐写编码方案 - Ruby 实现 ===\n"

# 演示 1：字符映射表
puts "【1. Unicode 同形字符映射表】"
stego.channels.each do |name, channel|
  puts "\n通道: #{name} (#{channel[:name]})"
  channel[:chars].each do |char_info|
    code = "U+#{char_info[:code].to_s(16).upcase.rjust(4, '0')}"
    puts "  #{code}  #{char_info[:name].ljust(16)}  => \"#{char_info[:char]}\""
  end
end

# 演示 2：容量计算
puts "\n\n【2. 文本容量计算】"
sample_text = "Today's date is 2026-07-02. The meeting starts at 14:00, and we'll discuss the project."
puts "示例文本: \"#{sample_text}\""
capacity = stego.get_capacity(sample_text)
counts = stego.count_available_slots(sample_text)
puts "各通道可用字符数: #{counts}"
puts "总编码容量: #{capacity} bits (#{capacity / 8.0} bytes)"

# 演示 3：编码与解码
puts "\n\n【3. 编码与解码演示】"
test_data = 0b1010101110 # 10-bit 测试数据
puts "待编码数据: #{test_data} (二进制: #{test_data.to_s(2).rjust(10, '0')})"

encoded = stego.encode(sample_text, test_data, 10)
puts "\n隐写文本: \"#{encoded[:stego_text]}\""
puts "使用的通道: #{encoded[:used_channels].keys}"

decoded = stego.decode(encoded[:stego_text], 10)
puts "\n解码数据: #{decoded[:data]} (二进制: #{decoded[:data].to_s(2).rjust(10, '0')})"
puts "数据匹配: #{test_data == decoded[:data] ? 'PASS' : 'FAIL'}"

# 演示 4：视觉对比
puts "\n\n【4. 视觉对比（肉眼不可区分）】"
puts "原始文本: #{sample_text}"
puts "隐写文本: #{encoded[:stego_text]}"
puts "两者在大多数字体下视觉上完全相同！"

# 演示 5：环境指纹编码
puts "\n\n【5. 环境指纹编码（模拟 Claude Code）】"
env = {
  time_zone: "Asia/Shanghai",
  has_proxy: true,
  is_china_domain: true,
  is_ai_lab: false,
  platform: "darwin",
  locale: "zh-CN",
}
fingerprint = stego.generate_fingerprint(env)
puts "环境信息: #{env}"
puts "生成指纹: #{fingerprint} (二进制: #{fingerprint.to_s(2).rjust(10, '0')})"

fingerprint_encoded = stego.encode(sample_text, fingerprint, 10)
puts "\n嵌入指纹后的文本: #{fingerprint_encoded[:stego_text]}"

fingerprint_decoded = stego.decode(fingerprint_encoded[:stego_text], 10)
parsed = stego.parse_fingerprint(fingerprint_decoded[:data])
puts "\n解析指纹: #{parsed}"

# 演示 6：检测与防御
puts "\n\n【6. 检测与防御】"
detection = stego.detect(fingerprint_encoded[:stego_text])
puts "检测结果: #{detection[:summary]}"
if detection[:suspicious] && !detection[:suspicious].empty?
  puts "可疑字符详情:"
  detection[:suspicious].each do |s|
    puts "  #{s[:channel]}: #{s[:name]} (#{s[:code]}) x #{s[:count]}"
  end
end

sanitized = stego.sanitize(fingerprint_encoded[:stego_text])
puts "\n清理后的文本: #{sanitized}"
after_sanitize = stego.detect(sanitized)
puts "清理后检测: #{after_sanitize[:summary]}"

# 演示 7：水印应用
puts "\n\n【7. 文档水印应用】"
document = "机密文件 - 仅供内部使用。请勿外传。"
watermark_id = 42 # 接收者 ID
watermarked = stego.encode(document, watermark_id, 10)
puts "原文档: \"#{document}\""
puts "水印 ID: #{watermark_id}"
puts "水印文档: \"#{watermarked[:stego_text]}\""

extracted = stego.decode(watermarked[:stego_text], 10)
puts "提取水印: #{extracted[:data]}"
puts "水印验证: #{watermark_id == extracted[:data] ? 'PASS' : 'FAIL'}"
