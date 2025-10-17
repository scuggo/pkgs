#! /usr/bin/env nix-shell
/*
#! nix-shell -i zx  -p nix-prefetch-github -p zx
*/

import { readFileSync, writeFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// GitHub API endpoint for latest release
const GITHUB_API = "https://api.github.com/repos/zed-industries/claude-code-acp/releases/latest";

// Read current info.json
const infoPath = join(__dirname, "info.json");
const currentInfo = JSON.parse(readFileSync(infoPath, "utf-8"));

console.log(`Current version: ${currentInfo.version}`);

// Fetch latest release from GitHub
console.log("Fetching latest release from GitHub...");
const response = await fetch(GITHUB_API);
const release = await response.json();

const latestVersion = release.tag_name.replace(/^v/, ""); // Remove 'v' prefix
console.log(`Latest version: ${latestVersion}`);

if (currentInfo.version === latestVersion) {
  console.log("Already up to date!");
  process.exit(0);
}

// Update version
currentInfo.version = latestVersion;

// Prefetch source hash
console.log("Prefetching source hash...");
const srcHashOutput = await $`nix-prefetch-github zed-industries claude-code-acp --rev v${latestVersion}`;
const srcPrefetch = JSON.parse(srcHashOutput.stdout);
currentInfo.srcHash = srcPrefetch.hash;

console.log(`Source hash: ${currentInfo.srcHash}`);

// Write temporary info.json to get npmDepsHash
writeFileSync(infoPath, JSON.stringify(currentInfo, null, 2) + "\n");

// Prefetch npm dependencies hash
console.log("Prefetching npm dependencies hash...");
try {
  // This will fail with the expected hash in the error message
  await $`nix build .#claude-code-acp`;

} catch (error) {
  // Extract hash from error message
  const errorOutput = error.stderr;
  const hashMatch = errorOutput.match(/got:\s+(sha256-[A-Za-z0-9+/=]+)/);

  if (hashMatch) {
    currentInfo.npmDepsHash = hashMatch[1];
    console.log(`npm deps hash: ${currentInfo.npmDepsHash}`);
  } else {
    console.error("Failed to extract npmDepsHash from build output");
    console.error("You may need to update it manually by running:");
    console.error(`  nix-build -A claude-code-acp`);
    console.error("and copying the hash from the error message");
  }
}

// Write final info.json
writeFileSync(infoPath, JSON.stringify(currentInfo, null, 2) + "\n");

console.log("\nUpdate complete!");
console.log(`Version: ${currentInfo.version}`);
console.log(`Source hash: ${currentInfo.srcHash}`);
console.log(`npm deps hash: ${currentInfo.npmDepsHash}`);
