#!/bin/bash
# Apply riverpod mock-safety patch for NotifierProvider testing with mockito.
# Required because mockito generates `implements` (not `extends`) mocks,
# and Dart's private method `_setElement` throws NoSuchMethodError on such mocks.
#
# Run after `flutter pub get`:
#   bash tool/apply_patches.sh

RIVERPOD_DIR=$(find ~/.pub-cache/hosted/pub.dev -maxdepth 1 -name "riverpod-2.*" -type d | sort -V | tail -1)

if [ -z "$RIVERPOD_DIR" ]; then
  echo "ERROR: riverpod package not found in pub cache"
  exit 1
fi

TARGET_FILE="$RIVERPOD_DIR/lib/src/notifier/base.dart"

if grep -q "on NoSuchMethodError" "$TARGET_FILE" 2>/dev/null; then
  echo "Patch already applied to $TARGET_FILE"
  exit 0
fi

sed -i.bak 's/return provider._createNotifier().._setElement(this);/final notifier = provider._createNotifier();\n      try {\n        notifier._setElement(this);\n      } on NoSuchMethodError {\n        \/\/ Allow mock notifiers (mockito implements, not extends)\n      }\n      return notifier;/' "$TARGET_FILE"

echo "Patch applied to $TARGET_FILE"
