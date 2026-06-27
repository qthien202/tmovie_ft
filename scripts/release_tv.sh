#!/bin/bash
# ============================================================
# TMovie TV - Build & Release Script
# Builds APK and creates a GitHub Release with the APK attached.
#
# Usage:
#   ./scripts/release_tv.sh              # Auto-bump patch (1.0.0 → 1.0.1)
#   ./scripts/release_tv.sh 1.2.0        # Set specific version
#   ./scripts/release_tv.sh --help       # Show help
#
# Prerequisites:
#   - GitHub CLI: brew install gh
#   - Login: gh auth login
# ============================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TV_DIR="$ROOT_DIR/apps/tv"
PUBSPEC="$TV_DIR/pubspec.yaml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Help ──────────────────────────────────────────────
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: ./scripts/release_tv.sh [VERSION]"
  echo ""
  echo "  VERSION   Optional. Semantic version (e.g. 1.2.0)"
  echo "            If omitted, auto-bumps patch version."
  echo ""
  echo "Examples:"
  echo "  ./scripts/release_tv.sh           # 1.0.0 → 1.0.1"
  echo "  ./scripts/release_tv.sh 2.0.0     # Set to 2.0.0"
  exit 0
fi

# ─── Check prerequisites ──────────────────────────────
if ! command -v gh &>/dev/null; then
  echo -e "${RED}Error: GitHub CLI (gh) not found.${NC}"
  echo "Install: brew install gh"
  echo "Login:   gh auth login"
  exit 1
fi

if ! gh auth status &>/dev/null 2>&1; then
  echo -e "${RED}Error: Not logged in to GitHub CLI.${NC}"
  echo "Run: gh auth login"
  exit 1
fi

# ─── Read current version ─────────────────────────────
CURRENT_VERSION=$(grep '^version:' "$PUBSPEC" | sed 's/version: //' | cut -d'+' -f1)
CURRENT_BUILD=$(grep '^version:' "$PUBSPEC" | sed 's/version: //' | cut -d'+' -f2)

echo -e "${CYAN}Current version: ${CURRENT_VERSION}+${CURRENT_BUILD}${NC}"

# ─── Determine new version ────────────────────────────
if [[ -n "${1:-}" ]]; then
  NEW_VERSION="$1"
else
  # Auto-bump patch
  IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
  PATCH=$((PATCH + 1))
  NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

NEW_BUILD=$((CURRENT_BUILD + 1))

echo -e "${GREEN}New version: ${NEW_VERSION}+${NEW_BUILD}${NC}"

# ─── Confirm ──────────────────────────────────────────
read -rp "Proceed with release v${NEW_VERSION}? (y/N) " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

# ─── Update pubspec.yaml ──────────────────────────────
echo -e "${YELLOW}Updating pubspec.yaml...${NC}"
sed -i '' "s/^version: .*/version: ${NEW_VERSION}+${NEW_BUILD}/" "$PUBSPEC"
echo -e "${GREEN}Updated to ${NEW_VERSION}+${NEW_BUILD}${NC}"

# ─── Build APK ────────────────────────────────────────
echo -e "${YELLOW}Building release APK...${NC}"
cd "$TV_DIR"
flutter build apk --release

APK_PATH="$TV_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo -e "${RED}Error: APK not found at $APK_PATH${NC}"
  exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "${GREEN}APK built: $APK_SIZE${NC}"

# ─── Rename APK ───────────────────────────────────────
RELEASE_APK="$TV_DIR/build/app/outputs/flutter-apk/tmovie-tv-v${NEW_VERSION}.apk"
cp "$APK_PATH" "$RELEASE_APK"

# ─── Create GitHub Release ────────────────────────────
TAG="v${NEW_VERSION}"
echo -e "${YELLOW}Creating GitHub Release ${TAG}...${NC}"

cd "$ROOT_DIR"

# Generate release notes from recent commits
NOTES=$(git log --oneline -10 --pretty=format:"- %s" 2>/dev/null || echo "- Release v${NEW_VERSION}")

gh release create "$TAG" \
  "$RELEASE_APK#TMovie TV v${NEW_VERSION}" \
  --title "TMovie TV v${NEW_VERSION}" \
  --notes "$NOTES" \
  --latest

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Release v${NEW_VERSION} created!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "APK: ${CYAN}tmovie-tv-v${NEW_VERSION}.apk${NC} (${APK_SIZE})"
echo -e "URL: $(gh release view "$TAG" --json url -q .url 2>/dev/null || echo 'Check GitHub')"
