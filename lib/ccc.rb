# frozen_string_literal: true

# CCC (Covert Channel Codec)
# Unicode homoglyph-based steganography for Ruby and JavaScript.
#
# This gem provides two core classes:
#   - Ccc::StegoEncoder:  Claude Code-style date/apostrophe covert channel
#   - Ccc::UnicodeStego:  General 5-channel Unicode homoglyph steganography

require_relative "ccc/version"
require_relative "ccc/stego_encoder"
require_relative "ccc/unicode_stego"

# Wrap bare classes into the Ccc namespace for gem isolation
module Ccc
  # StegoEncoder is already loaded from ccc/stego_encoder.rb
  # UnicodeStego is already loaded from ccc/unicode_stego.rb
end
