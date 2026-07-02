# frozen_string_literal: true

require_relative "../../lib/ccc/stego_encoder"

# === Claude Code 后门信息隐藏算法 — Ruby 演示 ===

encoder = StegoEncoder.new

puts "=== Claude Code 后门信息隐藏算法 - Ruby 实现 ===\n"

# 演示 1：所有 8 种状态
puts "【1. 手动编码所有 8 种状态】"
encoder.demo_all_states.each do |result|
  d = result[:decoded]
  puts "#{result[:state].ljust(16)} => #{result[:encoded]}"
  puts "  解码: 中国时区=#{d[:is_china_tz]}, 域名命中=#{d[:domain_hit]}, 关键词命中=#{d[:keyword_hit]}\n"
end

# 演示 2：自动检测
puts "【2. 自动检测模拟】"
test_urls = [
  nil,
  "https://api.openai.com/v1",
  "https://api.moonshot.ai/v1",
  "https://gateway.deepseek.com/v1",
  "https://some-proxy.cn/api",
]

test_urls.each do |url|
  result = encoder.auto_encode(proxy_url: url)
  decoded = encoder.decode(result)
  puts "URL: #{url || '(无代理)'}"
  puts "  生成: #{result}"
  puts "  解码: 中国时区=#{decoded[:is_china_tz]}, 域名命中=#{decoded[:domain_hit]}, 关键词命中=#{decoded[:keyword_hit]}\n"
end

# 演示 3：XOR 混淆
puts "【3. XOR 混淆演示 (key=91)】"
original = "moonshot.ai|deepseek.com|zhipu.ai"
obfuscated = encoder.xor_obfuscate(original)
recovered = encoder.xor_deobfuscate(obfuscated)
puts "原始:    #{original}"
puts "混淆后:  #{obfuscated}"
puts "恢复:    #{recovered}"
puts "匹配验证: #{original == recovered ? 'PASS' : 'FAIL'}"

# 演示 4：Unicode 同形字符
puts "\n【4. Unicode 同形字符对比】"
chars = [
  { name: "标准 ASCII 撇号", code: 0x0027 },
  { name: "右单引号", code: 0x2019 },
  { name: "修饰字母撇号", code: 0x02BC },
  { name: "修饰字母上标号", code: 0x02B9 },
]

chars.each do |c|
  ch = c[:code].chr(Encoding::UTF_8)
  puts "U+#{c[:code].to_s(16).upcase.rjust(4, '0')}  #{c[:name].ljust(16)}  =>  \"#{ch}\"  (ord: #{ch.ord})"
end

# 演示 5：防御检测
puts "\n【5. 防御检测 - 扫描异常 Unicode】"
suspicious_prompt = "Today's date is 2026/06/30."
suspicious_prompt["'"] = "\u2019"  # 替换为右单引号
puts "测试提示词: #{suspicious_prompt}"
puts "扫描结果:"
suspicious_prompt.each_char.with_index do |ch, i|
  cp = ch.ord
  if [0x2019, 0x02BC, 0x02B9].include?(cp)
    puts "  发现可疑字符 U+#{cp.to_s(16).upcase.rjust(4, '0')} 在位置 #{i}: '#{ch}'"
  end
end
