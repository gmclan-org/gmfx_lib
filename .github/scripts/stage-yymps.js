// Stages the contents of a GameMaker .yymps package containing only the
// resources that live inside the "gmfx_lib" folder of the project - i.e. the
// library itself, excluding the demo project/objects/room/sprite.
// Actual zipping is left to the `zip` CLI in the workflow step.
//
// Plain variant: metadata.json, gmfx_lib.resource_order, gmfx_lib.yyp, resources.
//
// --with-prefab variant (GMPM prefab package, layout matches GameMaker's own
// prefab .yymps files): gmfx_lib.gmclan-org-<version>.{resource_order,yyp,png},
// prefab.json, package.json, yymanifest.xml, resources.
//
// Usage: node stage-yymps.js <version> <stageDir> [--with-prefab]
// version: semver string, e.g. "0.2.0" (no leading "v")

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ROOT = path.resolve(__dirname, "..", "..");
const PACKAGE_ID = "gmfx_lib";
const GMPM_ID = `${PACKAGE_ID}.gmclan-org`;

function readJson5(filePath) {
  // .yy/.yyp files are JSON with trailing commas - strip them before parsing.
  const raw = fs.readFileSync(filePath, "utf8");
  const stripped = raw.replace(/,(\s*[}\]])/g, "$1");
  return JSON.parse(stripped);
}

function main() {
  const version = process.argv[2];
  const stageDir = process.argv[3];
  const withPrefab = process.argv.includes("--with-prefab");
  if (!version || !/^\d+\.\d+\.\d+$/.test(version) || !stageDir) {
    console.error("Usage: node stage-yymps.js <version like 0.2.0> <stageDir> [--with-prefab]");
    process.exit(1);
  }

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

  fs.mkdirSync(stageDir, { recursive: true });

  // metadata.json - only for the plain (non-prefab) .yymps variant; the
  // GMPM prefab variant uses package.json + prefab.json instead.
  if (!withPrefab) {
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
  }

  // <package>.resource_order - named after the GMPM package id when building
  // the prefab variant, matching GameMaker's own prefab .yymps layout.
  const baseName = withPrefab ? `${GMPM_ID}-${version}` : PACKAGE_ID;
  const resourceOrder = {
    FolderOrderSettings: [],
    ResourceOrderSettings: libResources.map((r, i) => ({
      name: r.id.name,
      order: i + 1,
      path: r.id.path,
    })),
  };
  const resourceOrderPath = path.join(stageDir, `${baseName}.resource_order`);
  writeGmJson(resourceOrderPath, resourceOrder);

  // <package>.yyp
  const packageYyp = {
    $GMProject: "v1",
    "%Name": baseName,
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
      PackagePublisher: "gmclan.org",
      PackageVersion: version,
    },
    name: baseName,
    resources: libResources.map((r) => ({ id: { name: r.id.name, path: r.id.path } })),
    resourceType: "GMProject",
    resourceVersion: "2.0",
    RoomOrderNodes: [],
    templateType: null,
    TextureGroups: yyp.TextureGroups,
  };
  const yypPath2 = path.join(stageDir, `${baseName}.yyp`);
  writeGmJson(yypPath2, packageYyp);

  // Files written so far, relative to stageDir, for the yymanifest below.
  const manifestFiles = [
    path.relative(stageDir, resourceOrderPath),
    path.relative(stageDir, yypPath2),
  ];

  // prefab.json, icon .png and yymanifest.xml - only for the GMPM prefab
  // variant, matching GameMaker's own prefab .yymps layout. package.json is
  // NOT part of the .yymps itself (GameMaker's own prefabs don't ship one
  // inside the archive) - it's written as a sibling of stageDir instead, for
  // the .tgz step to pick up.
  if (withPrefab) {
    const prefab = {
      $PrefabMetadata: "v2",
      Author: "gmclan.org",
      Description: "gmfx_lib animation lib",
      DisplayName: "gmfx_lib animation lib",
      Exports: libResources.map((r) => ({
        $PrefabExportMetadata: "v4",
        AssetName: r.id.name,
        Description: resourceTypeToDescription(readJson5(path.join(ROOT, r.id.path)).resourceType),
        DisplayName: r.id.name,
        FolderPath: PACKAGE_ID,
        ResourceType: readJson5(path.join(ROOT, r.id.path)).resourceType,
        ResourceVersion: 1,
      })),
      PackageId: GMPM_ID,
      Version: version,
    };
    const prefabPath = path.join(stageDir, "prefab.json");
    writeGmJson(prefabPath, prefab);
    manifestFiles.push(path.relative(stageDir, prefabPath));

    // package.json - copied from the repo root template, with version, the
    // packaged .yymps filename, and the icon data refreshed from gm-prefab.png
    // so the template file can't drift out of sync with the actual image.
    // Written next to stageDir (not inside it) since it isn't part of the
    // .yymps archive contents.
    const pkg = JSON.parse(fs.readFileSync(path.join(ROOT, "package.json"), "utf8"));
    pkg.version = version;
    pkg.files = [`${GMPM_ID}-${version}.yymps`];
    pkg.gm.icon.data = fs.readFileSync(path.join(ROOT, "gm-prefab.png")).toString("base64");
    const pkgJsonPath = `${stageDir}.package.json`;
    fs.writeFileSync(pkgJsonPath, JSON.stringify(pkg, null, 2) + "\n");

    // <package>.png - the icon, alongside package.json, as a standalone file.
    const iconPath = path.join(stageDir, `${baseName}.png`);
    fs.copyFileSync(path.join(ROOT, "gm-prefab.png"), iconPath);
    manifestFiles.push(path.relative(stageDir, iconPath));
  }

  // copy each resource's folder (e.g. scripts/fx_animation/*) into the stage dir
  for (const r of libResources) {
    const resDir = path.dirname(r.id.path);
    const srcDir = path.join(ROOT, resDir);
    const destDir = path.join(stageDir, resDir);
    fs.mkdirSync(destDir, { recursive: true });
    for (const file of fs.readdirSync(srcDir)) {
      const srcFile = path.join(srcDir, file);
      const destFile = path.join(destDir, file);
      fs.copyFileSync(srcFile, destFile);
      manifestFiles.push(path.relative(stageDir, destFile));
    }
  }

  // yymanifest.xml - lists every packaged file with its MD5 checksum, written
  // last since it must cover every other file already staged.
  if (withPrefab) {
    writeYyManifest(path.join(stageDir, "yymanifest.xml"), stageDir, manifestFiles);
  }

  console.log(`Staged package contents in ${stageDir}`);
}

function writeYyManifest(manifestPath, stageDir, relativeFiles) {
  const entries = relativeFiles
    .map((relPath) => {
      const md5 = crypto
        .createHash("md5")
        .update(fs.readFileSync(path.join(stageDir, relPath)))
        .digest("hex")
        .toUpperCase();
      const xmlPath = relPath.split(path.sep).join("\\");
      return `\t<file md5="${md5}">${xmlPath}</file>`;
    })
    .join("\n");
  const xml = `﻿<?xml version="1.0" encoding="utf-8"?>\n<files>\n${entries}\n</files>`;
  fs.writeFileSync(manifestPath, xml);
}

// Maps a GameMaker resourceType (e.g. "GMScript") to the human-readable
// description GameMaker shows for that asset kind in prefab.json.
function resourceTypeToDescription(resourceType) {
  const map = {
    GMScript: "Script",
    GMObject: "Object",
    GMSprite: "Sprite",
    GMShader: "Shader",
    GMFont: "Font",
    GMRoom: "Room",
    GMPath: "Path",
    GMSound: "Sound",
    GMTimeline: "Timeline",
    GMSequence: "Sequence",
    GMAnimCurve: "Animation Curve",
    GMTileSet: "Tile Set",
  };
  return map[resourceType] || resourceType;
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

main();
