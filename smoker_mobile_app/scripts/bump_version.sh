#!/bin/bash

# smoker_mobile_app version bumper
# Usage: ./scripts/bump_version.sh [major|minor|patch|build]

# Bump Build	./scripts/bump_version.sh build	1.0.1+3 → 1.0.1+4
# Bump Patch	./scripts/bump_version.sh patch	1.0.1+4 → 1.0.2+5
# Bump Minor	./scripts/bump_version.sh minor	1.0.2+5 → 1.1.0+6
# Bump Major	./scripts/bump_version.sh major	1.1.0+6 → 2.0.0+7

PUBSPEC="pubspec.yaml"

if [ ! -f "$PUBSPEC" ]; then
    echo "Error: pubspec.yaml not found in current directory."
    exit 1
fi

# Get current version line
VERSION_LINE=$(grep "^version: " "$PUBSPEC")
# Extract version and build
# Format: version: 1.0.0+1
VERSION_PART=$(echo $VERSION_LINE | cut -d' ' -f2 | cut -d'+' -f1)
BUILD_PART=$(echo $VERSION_LINE | cut -d'+' -f2)

# Split version into components
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_PART"

BUMP_TYPE=$1
if [ -z "$BUMP_TYPE" ]; then
    BUMP_TYPE="build"
fi

case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    patch)
        PATCH=$((PATCH + 1))
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    build)
        BUILD_PART=$((BUILD_PART + 1))
        ;;
    *)
        echo "Usage: $0 [major|minor|patch|build]"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH+$BUILD_PART"
echo "Bumping version from $VERSION_PART+$BUILD_PART to $NEW_VERSION"

# Use sed to replace the version line
# Note: Mac sed and Linux sed behave differently. This is for Linux as per user info.
sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"

echo "Updated $PUBSPEC successfully."
