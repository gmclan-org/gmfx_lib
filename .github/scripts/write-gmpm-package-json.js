// Writes the package.json that goes inside the GMPM .tgz package
// (stage/tgz/package/package.json), derived from the repo root package.json
// template but with `files` pointing only at the .yymps sitting next to it,
// matching GameMaker's own prefab .tgz layout (a "package" folder containing
// just the .yymps and package.json).
//
// Usage: node write-gmpm-package-json.js <version> <outFile>

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..", "..");
const PACKAGE_ID = "gmfx_lib";

function main() {
  const version = process.argv[2];
  const outFile = process.argv[3];
  if (!version || !/^\d+\.\d+\.\d+$/.test(version) || !outFile) {
    console.error("Usage: node write-gmpm-package-json.js <version like 0.2.0> <outFile>");
    process.exit(1);
  }

  const pkg = JSON.parse(fs.readFileSync(path.join(ROOT, "package.json"), "utf8"));
  pkg.version = version;
  pkg.files = [`${PACKAGE_ID}.gmclan-org-${version}.yymps`];
  pkg.gm.icon.data = fs.readFileSync(path.join(ROOT, "gm-prefab.png")).toString("base64");

  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, JSON.stringify(pkg, null, 2) + "\n");
}

main();
