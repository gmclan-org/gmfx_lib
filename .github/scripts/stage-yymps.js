// Stages the contents of the GMPM prefab .yymps package containing only the
// resources that live inside the "gmfx_lib" folder of the project - i.e. the
// library itself, excluding the demo project/objects/room/sprite. Layout
// matches GameMaker's own prefab .yymps files:
// org.gmclan.gmfx_lib-<version>.{resource_order,yyp,png}, prefab.json,
// package.json, yymanifest.xml, resources.
// Actual zipping is left to the `zip` CLI in the workflow step.
//
// Usage: node stage-yymps.js <version> <stageDir>
// version: semver string, e.g. "0.2.0" (no leading "v")

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const ROOT = path.resolve(__dirname, "..", "..");
const PACKAGE_ID = "gmfx_lib";
// GameMaker's own prefabs (and third-party ones the IDE actually lists, e.g.
// io.gamemaker.desertshooter, com.eightouncegames.cultured-runtime) use a
// reverse-DNS PackageId/filename. A package.json-style "name.scope" id (what
// this used to be) gets installed and downloads fine, but never shows up in
// the IDE's Prefabs list - confirmed by testing both side by side.
const GMPM_ID = `org.gmclan.${PACKAGE_ID}`;

function readJson5(filePath) {
  // .yy/.yyp files are JSON with trailing commas - strip them before parsing.
  const raw = fs.readFileSync(filePath, "utf8");
  const stripped = raw.replace(/,(\s*[}\]])/g, "$1");
  return JSON.parse(stripped);
}

function main() {
  const version = process.argv[2];
  const stageDir = process.argv[3];
  if (!version || !/^\d+\.\d+\.\d+$/.test(version) || !stageDir) {
    console.error("Usage: node stage-yymps.js <version like 0.2.0> <stageDir>");
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

  // <package>.resource_order - named after the GMPM package id, matching
  // GameMaker's own prefab .yymps layout.
  const baseName = `${GMPM_ID}-${version}`;
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

  // <package>.yyp - the GMPM prefab variant matches the shape GameMaker's own
  // installed prefabs have on disk (e.g. com.eightouncegames.cultured-runtime):
  // a ForcedPrefabProjectReferences key and a MetaData with only IDEVersion.
  // Folders must NOT be emptied for the prefab variant - prefab.json's
  // Exports[].FolderPath references it, and the IDE resolves prefabs against
  // this Folders list ("Could not find package X in the dependency graph" in
  // ui.log when it's missing).
  const packageYyp = {
    $GMProject: "v1",
    "%Name": baseName,
    AudioGroups: yyp.AudioGroups,
    configs: yyp.configs,
    defaultScriptType: yyp.defaultScriptType,
    Folders: yyp.Folders.filter((f) => f["%Name"] === PACKAGE_ID),
    ForcedPrefabProjectReferences: [],
    IncludedFiles: [],
    isEcma: yyp.isEcma,
    LibraryEmitters: [],
    MetaData: { IDEVersion: ideVersion },
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

  // prefab.json, package.json, icon .png and yymanifest.xml, matching
  // GameMaker's own prefab .yymps layout.
  const prefab = {
    $PrefabMetadata: "v2",
    Author: "gmclan.org",
    Description: "gmfx_lib - Animation an tween library",
    DisplayName: "gmfx_lib",
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
  // Written both inside stageDir (GameMaker's own IDE-exported prefab
  // .yymps files ship package.json inside the archive - confirmed by
  // comparing against one the IDE built directly) and as a sibling of
  // stageDir, for the .tgz step to pick up.
  const pkg = JSON.parse(fs.readFileSync(path.join(ROOT, "package.json"), "utf8"));
  pkg.version = version;
  pkg.files = [`${GMPM_ID}-${version}.yymps`];
  pkg.gm.icon = {
    mime: "image/png",
    data: fs.readFileSync(path.join(ROOT, "gm-prefab.png")).toString("base64"),
  };
  const pkgJson = JSON.stringify(pkg, null, 2) + "\n";
  fs.writeFileSync(`${stageDir}.package.json`, pkgJson);
  const pkgJsonInsidePath = path.join(stageDir, "package.json");
  fs.writeFileSync(pkgJsonInsidePath, pkgJson);
  manifestFiles.push(path.relative(stageDir, pkgJsonInsidePath));

  // <package>.png - the icon, alongside package.json, as a standalone file.
  const iconPath = path.join(stageDir, `${baseName}.png`);
  fs.copyFileSync(path.join(ROOT, "gm-prefab.png"), iconPath);
  manifestFiles.push(path.relative(stageDir, iconPath));

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
  writeYyManifest(path.join(stageDir, "yymanifest.xml"), stageDir, manifestFiles);

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

// GameMaker's own files use trailing commas after every entry/array item,
// and no space after the ":" in key/value pairs. Reproduce that style so the
// output stays consistent with native .yy/.yyp files.
function writeGmJson(filePath, obj) {
  const json = JSON.stringify(obj, null, 2);
  const withTrailingCommas = json
    .replace(/([}\]"0-9a-zA-Z])\n(\s*[}\]])/g, "$1,\n$2")
    .replace(/,(\s*)$/, "$1") // no trailing comma after the very last closing brace
    .replace(/": /g, '":');
  fs.writeFileSync(filePath, withTrailingCommas + (withTrailingCommas.endsWith("\n") ? "" : "\n"));
}

main();
