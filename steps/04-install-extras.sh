#!/bin/bash -eux

SOURCE="${PDFium_SOURCE_DIR:-pdfium}"
OS="${PDFium_TARGET_OS:?}"
CPU="${PDFium_TARGET_CPU:?}"

pushd "$SOURCE"

case "$OS" in
  linux)
    build/install-build-deps.sh
    gclient runhooks
    build/linux/sysroot_scripts/install-sysroot.py "--arch=$CPU"
    ;;

  android)
    # User moder dependency installer
    COMMIT=6f78132b7587bc8532006c2f233aaf0a1a5818c3
    REPO="https://chromium.googlesource.com/chromium/src/build.git/+"
    curl "$REPO/$COMMIT/install-build-deps.sh?format=TEXT" | base64 --decode > build/install-build-deps.sh && chmod +x build/install-build-deps.sh
    curl "$REPO/$COMMIT/install-build-deps.py?format=TEXT" | base64 --decode > build/install-build-deps.py && chmod +x build/install-build-deps.py

    build/install-build-deps.sh --android
    gclient runhooks
    ;;
esac

popd
