/**
 * CCC (Covert Channel Codec) – JavaScript entry point
 *
 * Exports both encoder implementations:
 *   - StegoEncoder:   Claude Code–style date/apostrophe covert channel
 *   - UnicodeStego:   General 5-channel Unicode homoglyph steganography
 */

const { StegoEncoder } = require("./stego_encoder");
const { UnicodeStego } = require("./unicode_stego");

module.exports = {
  StegoEncoder,
  UnicodeStego,
};
