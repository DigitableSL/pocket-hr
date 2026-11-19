#!/bin/sh
set -e

# Navigate to repository root
cd "$CI_PRIMARY_REPOSITORY_PATH"

# 1. Resolve tenant (from Xcode Cloud env var TENANT, or from CI_TAG like ios-domex-v1.2.4+31)
TENANT_VAL="${TENANT:-}"
if [ -z "$TENANT_VAL" ] && [ -n "${CI_TAG:-}" ]; then
  case "$CI_TAG" in
    ios-*-v*)
      TENANT_VAL=$(echo "$CI_TAG" | sed -E 's/^ios-([a-z]+)-v.*/\1/')
      ;;
  esac
fi
TENANT_VAL="${TENANT_VAL:-domex}"
TARGET="lib/main_${TENANT_VAL}.dart"

# 2. Resolve version name and build number
PUBSPEC_LINE=$(grep -E '^version:' pubspec.yaml | head -n1)
PUBSPEC_NAME=$(echo "$PUBSPEC_LINE" | sed -n 's/^version:[[:space:]]*\([0-9][0-9.]*\).*/\1/p')
PUBSPEC_BUILD=$(echo "$PUBSPEC_LINE" | sed -n 's/.*+\([0-9][0-9]*\).*/\1/p')

BUILD_NAME="${PUBSPEC_NAME:-1.0.0}"
BASE_BUILD="${PUBSPEC_BUILD:-0}"
BUILD_NUMBER=$((BASE_BUILD + ${CI_BUILD_NUMBER:-1}))

if [ -n "${CI_TAG:-}" ]; then
  TAG_CORE="${CI_TAG%-prod}"
  VER_PART="${TAG_CORE#ios-${TENANT_VAL}-v}"
  PARSED_NAME=$(echo "$VER_PART" | sed -n 's/^\([0-9][0-9.]*\).*/\1/p')
  PARSED_NUM=$(echo "$VER_PART" | sed -n 's/^[0-9][0-9.]*[+b-]*\([0-9][0-9]*\)$/\1/p')
  if [ -n "$PARSED_NAME" ]; then
    BUILD_NAME="$PARSED_NAME"
  fi
  if [ -n "$PARSED_NUM" ] && [ "$VER_PART" != "$PARSED_NAME" ]; then
    BUILD_NUMBER="$PARSED_NUM"
  fi
fi

echo "=== Xcode Cloud Flutter Setup ==="
echo "Tenant:       $TENANT_VAL"
echo "Target:       $TARGET"
echo "Version:      $BUILD_NAME ($BUILD_NUMBER)"

# 3. Install Flutter SDK (pinned to match CI)
FLUTTER_VERSION="3.47.9"
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
fi
export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter config --no-enable-swift-package-manager || true
flutter precache --ios

# 4. Prepare tenant iOS assets, Firebase plist, and Info.plist
chmod +x tooling/prepare_ios_flavor.sh
./tooling/prepare_ios_flavor.sh "$TENANT_VAL"

# 5. Fetch Dart packages & generate ios/Flutter/Generated.xcconfig
flutter pub get
flutter build ios --release --config-only --no-codesign \
  -t "$TARGET" \
  --dart-define="tenant=${TENANT_VAL}" \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER"

# 6. Install CocoaPods dependencies
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

cd ios
pod install
exit 0
