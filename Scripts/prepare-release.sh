#!/usr/bin/env bash
# prepare-release.sh — local release gates for VenPaysApplePay
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: Scripts/prepare-release.sh <semver> [--dry-run]

Validates semantic version format, clean git status, version consistency,
required documentation, package resolve, and iOS build/tests.

Does NOT create or push tags by default.
EOF
}

DRY_RUN=0
VERSION=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$VERSION" ]]; then
        VERSION="$arg"
      else
        echo "error: unexpected argument: $arg" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "error: version argument required" >&2
  usage >&2
  exit 2
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "error: version '$VERSION' is not a valid semantic version" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -n "${DEVELOPER_DIR:-}" ]]; then
  :
elif [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

echo "==> VenPaysApplePay release preparation for v${VERSION}"
echo "    DEVELOPER_DIR=${DEVELOPER_DIR:-"(unset)"}"
echo "    dry-run=${DRY_RUN}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: git working tree is not clean" >&2
  git status --short >&2
  exit 1
fi

SDK_VERSION_FILE="Sources/VenPaysApplePay/Internal/SDKVersion.swift"
if ! grep -q "static let current = \"${VERSION}\"" "$SDK_VERSION_FILE"; then
  echo "error: SDKVersion.current does not match ${VERSION}" >&2
  grep -n "current =" "$SDK_VERSION_FILE" >&2 || true
  exit 1
fi

if ! grep -Eq "^## \[${VERSION}\]" CHANGELOG.md && ! grep -Eq "^## \[${VERSION}\] - Unreleased" CHANGELOG.md; then
  if grep -Eq "^## \[0\.1\.0\] - Unreleased" CHANGELOG.md && [[ "$VERSION" == "0.1.0" ]]; then
    echo "ok: CHANGELOG contains [0.1.0] - Unreleased"
  else
    echo "error: CHANGELOG.md missing section for ${VERSION} (or Unreleased for 0.1.0)" >&2
    exit 1
  fi
fi

REQUIRED_DOCS=(
  README.md
  CHANGELOG.md
  LICENSE
  Documentation/APIReference.md
  Documentation/SecurityModel.md
  Documentation/IntegrationGuide.md
  Documentation/BackendIntegration.md
  Documentation/ErrorReference.md
  Documentation/ReleaseChecklist.md
  Documentation/ReleaseValidationReportTemplate.md
  Documentation/CI.md
  Documentation/CompatibilityMatrix.md
)

for f in "${REQUIRED_DOCS[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "error: required file missing: $f" >&2
    exit 1
  fi
done
echo "ok: required documentation present"

run() {
  echo "==> $*"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "    (dry-run) skipped"
    return 0
  fi
  "$@"
}

run swift package resolve

# Host swift build/test are best-effort for an iOS-only package.
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "==> swift build (dry-run) skipped"
  echo "==> swift test (dry-run) skipped"
else
  echo "==> swift build (best-effort)"
  swift build || echo "warning: swift build failed on host; continuing with xcodebuild"
  echo "==> swift test (best-effort)"
  swift test || echo "warning: swift test failed on host; continuing with xcodebuild"
fi

run xcodebuild -list

run xcodebuild \
  -scheme VenPaysApplePay \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "==> simulator test (dry-run) skipped"
else
  mkdir -p .build/test-results
  DEST_LINE=$(xcodebuild -scheme VenPaysApplePay -showdestinations 2>/dev/null \
    | grep 'platform:iOS Simulator' \
    | grep 'arch:arm64' \
    | grep 'id:' \
    | head -n 1 || true)
  if [[ -z "${DEST_LINE}" ]]; then
    echo "error: no iOS Simulator destination available" >&2
    exit 1
  fi
  SIM_ID=$(echo "${DEST_LINE}" | sed -n 's/.*id:\([A-F0-9-]*\).*/\1/p')
  echo "==> simulator id=${SIM_ID}"
  xcodebuild \
    -scheme VenPaysApplePay \
    -destination "platform=iOS Simulator,id=${SIM_ID}" \
    -parallel-testing-enabled NO \
    -resultBundlePath .build/test-results/VenPaysApplePay.xcresult \
    CODE_SIGNING_ALLOWED=NO \
    test | tee .build/test-results/xcodebuild-test.log
fi

cat <<EOF

==> Local gates completed for ${VERSION}

This script did NOT create or push a tag.

Exact next commands (signed tag example):

  git tag -s "v${VERSION}" -m "VenPaysApplePay ${VERSION}"
  git push origin "v${VERSION}"

For a release candidate:

  git tag -s "v${VERSION}-rc.1" -m "VenPaysApplePay ${VERSION} RC1"
  git push origin "v${VERSION}-rc.1"

Never print or commit secrets.
EOF
