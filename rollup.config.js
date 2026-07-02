// Rollup configuration for CCC (Covert Channel Codec)
// Builds three bundles: ESM, CommonJS, and UMD for browser use

import resolve from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";

const pkg = {
  name: "ccc-stego",
  version: "0.1.0",
};

const banner = `/*! ${pkg.name} v${pkg.version} | MIT License */`;

export default [
  // 1. ESM build (modern bundlers, Node.js ESM)
  {
    input: "src/index.js",
    output: {
      file: "dist/ccc.esm.js",
      format: "es",
      banner,
      exports: "named",
    },
    plugins: [resolve(), commonjs()],
  },

  // 2. CommonJS build (Node.js require)
  {
    input: "src/index.js",
    output: {
      file: "dist/ccc.cjs.js",
      format: "cjs",
      banner,
      exports: "named",
    },
    plugins: [resolve(), commonjs()],
  },

  // 3. UMD build (browser <script> tag)
  {
    input: "src/index.js",
    output: {
      file: "dist/ccc.umd.js",
      format: "umd",
      name: "Ccc",
      banner,
      exports: "named",
      globals: {},
    },
    plugins: [resolve(), commonjs()],
  },
];
