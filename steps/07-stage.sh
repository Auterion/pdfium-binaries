#!/bin/bash -eux

IS_DEBUG=${PDFium_IS_DEBUG:-false}
OS=${PDFium_TARGET_OS:?}
VERSION=${PDFium_VERSION:-}
PATCHES="$PWD/patches"

SOURCE=${PDFium_SOURCE_DIR:-pdfium}
BUILD=${PDFium_BUILD_DIR:-pdfium/out}

STAGING="$PWD/staging"
STAGING_BIN="$STAGING/bin"
STAGING_LIB="$STAGING/lib"
INCLUDE_DIR="$STAGING/include"

mkdir -p "$STAGING"
mkdir -p "$STAGING_LIB"

sed "s/#VERSION#/${VERSION:-0.0.0.0}/" <"$PATCHES/PDFiumConfig.cmake" >"$STAGING/PDFiumConfig.cmake"

cp "$SOURCE/LICENSES" "$STAGING/LICENSE"
cp "$BUILD/args.gn" "$STAGING"
cp -R "$SOURCE/public" "$INCLUDE_DIR"

# Add all other includes necessary for GDAL
HEADER_SUBDIRS="build constants fpdfsdk core/fxge core/fxge/agg core/fxge/dib core/fpdfdoc core/fpdfapi/parser core/fpdfapi/page core/fpdfapi/render core/fxcrt third_party/agg23 third_party/base third_party/base/allocator/partition_allocator third_party/base/numerics"
for subdir in $HEADER_SUBDIRS; do
    mkdir -p "$INCLUDE_DIR/$subdir"
    cp "$SOURCE/$subdir"/*.h "$INCLUDE_DIR/$subdir"
done
mkdir -p "$INCLUDE_DIR/third_party/abseil-cpp/absl/types"
cp "$SOURCE/third_party/abseil-cpp/absl/types"/*.h "$INCLUDE_DIR/third_party/abseil-cpp/absl/types"
mkdir -p "$INCLUDE_DIR/absl/base"
cp "$SOURCE/third_party/abseil-cpp/absl/base"/*.h "$INCLUDE_DIR/absl/base"
mkdir -p "$INCLUDE_DIR/absl/base/internal"
cp "$SOURCE/third_party/abseil-cpp/absl/base/internal"/*.h "$INCLUDE_DIR/absl/base/internal"
mkdir -p "$INCLUDE_DIR/absl/meta"
cp "$SOURCE/third_party/abseil-cpp/absl/meta"/*.h "$INCLUDE_DIR/absl/meta"
mkdir -p "$INCLUDE_DIR/absl/memory"
cp "$SOURCE/third_party/abseil-cpp/absl/memory"/*.h "$INCLUDE_DIR/absl/memory"
mkdir -p "$INCLUDE_DIR/absl/types"
cp "$SOURCE/third_party/abseil-cpp/absl/types"/*.h "$INCLUDE_DIR/absl/types"
mkdir -p "$INCLUDE_DIR/absl/types/internal"
cp "$SOURCE/third_party/abseil-cpp/absl/types/internal"/*.h "$INCLUDE_DIR/absl/types/internal"
mkdir -p "$INCLUDE_DIR/absl/utility"
cp "$SOURCE/third_party/abseil-cpp/absl/utility"/*.h "$INCLUDE_DIR/absl/utility"

rm -f "$INCLUDE_DIR/DEPS"
rm -f "$INCLUDE_DIR/README"
rm -f "$INCLUDE_DIR/PRESUBMIT.py"

case "$OS" in
  android|linux)
    mv "$BUILD/libpdfium.so" "$STAGING_LIB"
    ;;

  mac|ios)
    mv "$BUILD/libpdfium.dylib" "$STAGING_LIB"
    ;;

  wasm)
    mv "$BUILD/pdfium.html" "$STAGING_LIB"
    mv "$BUILD/pdfium.js" "$STAGING_LIB"
    mv "$BUILD/pdfium.wasm" "$STAGING_LIB"
    rm -rf "$INCLUDE_DIR/cpp"
    rm "$STAGING/PDFiumConfig.cmake"
    ;;

  win)
    mv "$BUILD/pdfium.dll.lib" "$STAGING_LIB"
    mkdir -p "$STAGING_BIN"
    mv "$BUILD/pdfium.dll" "$STAGING_BIN"
    [ "$IS_DEBUG" == "true" ] && mv "$BUILD/pdfium.dll.pdb" "$STAGING_BIN"
    ;;
esac

if [ -n "$VERSION" ]; then
  cat >"$STAGING/VERSION" <<END
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)
BUILD=$(echo "$VERSION" | cut -d. -f3)
PATCH=$(echo "$VERSION" | cut -d. -f4)
END
fi