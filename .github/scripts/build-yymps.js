// Builds a GameMaker .yymps package (a customized zip) containing only the
// resources that live inside the "gmfx_lib" folder of the project - i.e. the
// library itself, excluding the demo project/objects/room/sprite.
//
// Usage: node build-yymps.js <version> [outFile]
// version: semver string, e.g. "0.2.0" (no leading "v")

const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const ROOT = path.resolve(__dirname, "..", "..");
const PACKAGE_ID = "gmfx_lib";

function readJson5(filePath) {
  // .yy/.yyp files are JSON with trailing commas - strip them before parsing.
  const raw = fs.readFileSync(filePath, "utf8");
  const stripped = raw.replace(/,(\s*[}\]])/g, "$1");
  return JSON.parse(stripped);
}

function main() {
  const version = process.argv[2];
  if (!version || !/^\d+\.\d+\.\d+$/.test(version)) {
    console.error('Usage: node build-yymps.js <version like 0.2.0> [outFile]');
    process.exit(1);
  }
  const outFile = process.argv[3] || path.join(ROOT, `${PACKAGE_ID}.yymps`);

  const yypPath = path.join(ROOT, `${PACKAGE_ID}.yyp`);
  const yyp = readJson5(yypPath);

  const ideVersion = yyp.MetaData && yyp.MetaData.IDEVersion;
  if (!ideVersion) {
    throw new Error(`Could not find MetaData.IDEVersion in ${yypPath}`);
  }

  // Keep only resources whose own .yy file declares parent.name === PACKAGE_ID
  // (i.e. resources placed in the "gmfx_lib" folder in the IDE, not "demo").
  const libResources = yyp.resources.filter((r) => {
    const resYyPath = path.join(ROOT, r.id.path);
    const resYy = readJson5(resYyPath);
    return resYy.parent && resYy.parent.name === PACKAGE_ID;
  });

  if (libResources.length === 0) {
    throw new Error(`No resources found under the "${PACKAGE_ID}" folder`);
  }

  const stageDir = fs.mkdtempSync(path.join(require("os").tmpdir(), "yymps-"));
  try {
    // metadata.json
    const metadata = {
      package_id: PACKAGE_ID,
      display_name: PACKAGE_ID,
      version,
      package_type: "asset",
      ide_version: ideVersion,
    };
    fs.writeFileSync(
      path.join(stageDir, "metadata.json"),
      JSON.stringify(metadata, null, 2)
    );

    // <package>.resource_order
    const resourceOrder = {
      FolderOrderSettings: [],
      ResourceOrderSettings: libResources.map((r, i) => ({
        name: r.id.name,
        order: i + 1,
        path: r.id.path,
      })),
    };
    writeGmJson(
      path.join(stageDir, `${PACKAGE_ID}.resource_order`),
      resourceOrder
    );

    // <package>.yyp
    const packageYyp = {
      $GMProject: "",
      "%Name": PACKAGE_ID,
      AudioGroups: yyp.AudioGroups,
      configs: yyp.configs,
      defaultScriptType: yyp.defaultScriptType,
      Folders: yyp.Folders.filter((f) => f["%Name"] === PACKAGE_ID),
      IncludedFiles: [],
      isEcma: yyp.isEcma,
      LibraryEmitters: [],
      MetaData: {
        IDEVersion: ideVersion,
        PackageType: "Asset",
        PackageName: PACKAGE_ID,
        PackageID: PACKAGE_ID,
        PackagePublisher: "gnysek",
        PackageVersion: version,
      },
      name: PACKAGE_ID,
      resources: libResources.map((r) => ({ id: { name: r.id.name, path: r.id.path } })),
      resourceType: "GMProject",
      resourceVersion: "2.0",
      RoomOrderNodes: [],
      templateType: null,
      TextureGroups: yyp.TextureGroups,
    };
    writeGmJson(path.join(stageDir, `${PACKAGE_ID}.yyp`), packageYyp);

    // copy each resource's folder (e.g. scripts/fx_animation/*) into the stage dir
    for (const r of libResources) {
      const resDir = path.dirname(r.id.path);
      const srcDir = path.join(ROOT, resDir);
      const destDir = path.join(stageDir, resDir);
      fs.mkdirSync(destDir, { recursive: true });
      for (const file of fs.readdirSync(srcDir)) {
        fs.copyFileSync(path.join(srcDir, file), path.join(destDir, file));
      }
    }

    if (fs.existsSync(outFile)) fs.rmSync(outFile);
    zipDir(stageDir, outFile);
    console.log(`Built ${outFile}`);
  } finally {
    fs.rmSync(stageDir, { recursive: true, force: true });
  }
}

// GameMaker's own files use trailing commas after every entry/array item.
// Reproduce that style so the output stays consistent with native .yy/.yyp files.
function writeGmJson(filePath, obj) {
  const json = JSON.stringify(obj, null, 2);
  const withTrailingCommas = json
    .replace(/([}\]"0-9a-zA-Z])\n(\s*[}\]])/g, "$1,\n$2")
    .replace(/,(\s*)$/, "$1"); // no trailing comma after the very last closing brace
  fs.writeFileSync(filePath, withTrailingCommas + (withTrailingCommas.endsWith("\n") ? "" : "\n"));
}

// Minimal dependency-free ZIP writer (store + deflate), so this script runs
// identically on any OS/runner without relying on an external `zip` binary.
function zipDir(dir, outFile) {
  const files = [];
  (function walk(sub) {
    for (const entry of fs.readdirSync(path.join(dir, sub), { withFileTypes: true })) {
      const rel = path.join(sub, entry.name);
      if (entry.isDirectory()) walk(rel);
      else files.push(rel);
    }
  })("");

  const localParts = [];
  const centralParts = [];
  let offset = 0;

  for (const rel of files) {
    const zipPath = rel.split(path.sep).join("/");
    const data = fs.readFileSync(path.join(dir, rel));
    const crc = crc32(data);
    const compressed = zlib.deflateRawSync(data);
    const useDeflate = compressed.length < data.length;
    const payload = useDeflate ? compressed : data;
    const method = useDeflate ? 8 : 0;
    const nameBuf = Buffer.from(zipPath, "utf8");

    const localHeader = Buffer.alloc(30);
    localHeader.writeUInt32LE(0x04034b50, 0);
    localHeader.writeUInt16LE(20, 4); // version needed
    localHeader.writeUInt16LE(0, 6); // flags
    localHeader.writeUInt16LE(method, 8);
    localHeader.writeUInt16LE(0, 10); // mod time
    localHeader.writeUInt16LE(0, 12); // mod date
    localHeader.writeUInt32LE(crc, 14);
    localHeader.writeUInt32LE(payload.length, 18);
    localHeader.writeUInt32LE(data.length, 22);
    localHeader.writeUInt16LE(nameBuf.length, 26);
    localHeader.writeUInt16LE(0, 28);

    localParts.push(localHeader, nameBuf, payload);

    const centralHeader = Buffer.alloc(46);
    centralHeader.writeUInt32LE(0x02014b50, 0);
    centralHeader.writeUInt16LE(20, 4); // version made by
    centralHeader.writeUInt16LE(20, 6); // version needed
    centralHeader.writeUInt16LE(0, 8); // flags
    centralHeader.writeUInt16LE(method, 10);
    centralHeader.writeUInt16LE(0, 12); // mod time
    centralHeader.writeUInt16LE(0, 14); // mod date
    centralHeader.writeUInt32LE(crc, 16);
    centralHeader.writeUInt32LE(payload.length, 20);
    centralHeader.writeUInt32LE(data.length, 24);
    centralHeader.writeUInt16LE(nameBuf.length, 28);
    centralHeader.writeUInt16LE(0, 30); // extra len
    centralHeader.writeUInt16LE(0, 32); // comment len
    centralHeader.writeUInt16LE(0, 34); // disk number
    centralHeader.writeUInt16LE(0, 36); // internal attrs
    centralHeader.writeUInt32LE(0, 38); // external attrs
    centralHeader.writeUInt32LE(offset, 42);

    centralParts.push(centralHeader, nameBuf);

    offset += localHeader.length + nameBuf.length + payload.length;
  }

  const centralDirStart = offset;
  const centralDir = Buffer.concat(centralParts);
  const centralDirSize = centralDir.length;

  const eocd = Buffer.alloc(22);
  eocd.writeUInt32LE(0x06054b50, 0);
  eocd.writeUInt16LE(0, 4);
  eocd.writeUInt16LE(0, 6);
  eocd.writeUInt16LE(files.length, 8);
  eocd.writeUInt16LE(files.length, 10);
  eocd.writeUInt32LE(centralDirSize, 12);
  eocd.writeUInt32LE(centralDirStart, 16);
  eocd.writeUInt16LE(0, 20);

  fs.writeFileSync(outFile, Buffer.concat([...localParts, centralDir, eocd]));
}

let crcTable = null;
function crc32(buf) {
  if (!crcTable) {
    crcTable = new Uint32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) {
        c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      }
      crcTable[n] = c;
    }
  }
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    crc = crcTable[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

main();
