#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <version> [changelog note]"
  echo "Example: $0 0.1.4 \"Toolbar polish\""
  exit 1
fi

VERSION="$1"
NOTE="${2:-Release update}"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid version: $VERSION"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAIN_FILE="$ROOT_DIR/THEMEwerk.lua"
INDEX_FILE="$ROOT_DIR/index.xml"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"

for f in "$MAIN_FILE" "$INDEX_FILE" "$CHANGELOG_FILE"; do
  [[ -f "$f" ]] || { echo "Missing file: $f"; exit 1; }
done

DATE_UTC="$(date -u +%Y-%m-%d)"
TIME_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 1) Update THEMEwerk.lua @version
perl -i -pe "s/^-- \\@version .*/-- \\@version ${VERSION}/" "$MAIN_FILE"

# 2) Update index.xml vrs + prepend new <version> cloned from latest block
REL_VERSION="$VERSION" REL_TIME="$TIME_UTC" perl -0777 -i -pe '
  my $v = $ENV{"REL_VERSION"};
  my $t = $ENV{"REL_TIME"};

  if (/<version\s+name="$v"\b/) {
    die "index.xml already contains version $v\\n";
  }

  s/(<reapack\b[^>]*\bvrs=")([^"]+)(")/$1.$v.$3/e;

  if (/<version\s+name="[^"]+"[^>]*>.*?<\/version>\s*/s) {
    my $block = $&;
    $block =~ s/name="[^"]+"/name="$v"/;
    $block =~ s/time="[^"]+"/time="$t"/;
    s/(<\/metadata>\s*)/$1\n$block/s;
  } else {
    die "Could not find a <version> block to clone in index.xml\\n";
  }
' "$INDEX_FILE"

# 3) Prepend changelog entry if missing
if ! grep -q "^## \[$VERSION\] - $DATE_UTC$" "$CHANGELOG_FILE"; then
  tmp="$(mktemp)"
  {
    echo "# Changelog"
    echo
    echo "## [$VERSION] - $DATE_UTC"
    echo
    echo "### Changed"
    echo "- $NOTE"
    echo
    awk 'BEGIN{drop=1}
      drop && NR==1 && $0=="# Changelog" {next}
      drop && NR==2 && $0=="" {drop=0; next}
      {print}' "$CHANGELOG_FILE"
  } > "$tmp"
  mv "$tmp" "$CHANGELOG_FILE"
fi

echo "Release files updated:" \
  "$MAIN_FILE" \
  "$INDEX_FILE" \
  "$CHANGELOG_FILE"

echo "Version: $VERSION"
