{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
let
  info = lib.importJSON ./info.json;
in
buildNpmPackage {
  pname = "claude-code-acp";
  version = info.version;

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "claude-code-acp";
    rev = "v${info.version}";
    hash = info.srcHash;
  };

  npmDepsHash = info.npmDepsHash;

  # The package uses TypeScript and builds before publishing
  npmBuildScript = "build";

  passthru = {
    updateScript = ./update.mjs;
  };

  meta = {
    description = "Use Claude Code from any ACP client such as Zed";
    homepage = "https://github.com/zed-industries/claude-code-acp";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "claude-code-acp";
  };
}
