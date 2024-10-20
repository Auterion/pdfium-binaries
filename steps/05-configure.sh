#!/bin/bash -eux

OS=${PDFium_TARGET_OS:?}
SOURCE=${PDFium_SOURCE_DIR:-pdfium}
BUILD=${PDFium_BUILD_DIR:-$SOURCE/out}
TARGET_CPU=${PDFium_TARGET_CPU:?}
TARGET_ENVIRONMENT=${PDFium_TARGET_ENVIRONMENT:-default}
ENABLE_V8=${PDFium_ENABLE_V8:-false}
IS_DEBUG=${PDFium_IS_DEBUG:-false}

mkdir -p "$BUILD"

(
  echo "is_debug = $IS_DEBUG"
  echo "pdf_is_standalone = true"
  echo "pdf_use_partition_alloc = false"
  echo "target_cpu = \"$TARGET_CPU\""
  echo "target_os = \"$OS\""
  echo "pdf_enable_v8 = $ENABLE_V8"  # Should be false - no need for JavaScript.
  echo "pdf_enable_xfa = $ENABLE_V8"
  echo "treat_warnings_as_errors = false"
  echo "is_component_build = false"
  echo "pdf_use_skia = false"        # Disable experimental Skia backend
  echo "pdf_use_skia_paths = false"  # Disable experimental Skia paths backend
  echo "pdf_is_complete_lib = true"
  echo "use_custom_libcxx = false"   # Avoid incompatible namespace std::1::
  echo "use_rtti = true"             # Enable RTTI for virtual class subclassing
  echo "use_system_libjpeg = true"
  echo "use_system_libpng = true"
  echo "use_system_lcms2 = true"
  echo "use_system_libopenjpeg2 = true"
  echo "use_sysroot = false"         # Prevent fetching incompatible headers

  if [ "$ENABLE_V8" == "true" ]; then
    echo "v8_use_external_startup_data = false"
    echo "v8_enable_i18n_support = false"
  fi

  case "$OS" in
    android)
      echo "clang_use_chrome_plugins = false"
      echo "default_min_sdk_version = 21"  # Can change this if needed
      ;;
    ios)
      [ -n "$TARGET_ENVIRONMENT" ] && echo "target_environment = \"$TARGET_ENVIRONMENT\""
      echo "ios_enable_code_signing = false"
      echo "use_blink = true"
      [ "$ENABLE_V8" == "true" ] && [ "$TARGET_CPU" == "arm64" ] && echo 'arm_control_flow_integrity = "none"'
      echo "clang_use_chrome_plugins = false"
      ;;
    linux)
      echo "clang_use_chrome_plugins = false"
      ;;
    mac)
      echo 'mac_deployment_target = "10.13.0"'
      echo "clang_use_chrome_plugins = false"
      ;;
    wasm)
      echo 'is_clang = false'
      ;;
  esac

  case "$TARGET_ENVIRONMENT" in
    musl)
      echo 'is_musl = true'
      echo 'is_clang = false'
      # 'use_custom_libcxx = false' is already set globally
      if [ "$ENABLE_V8" == "true" ]; then
        case "$TARGET_CPU" in
          arm)
            echo "v8_snapshot_toolchain = \"//build/toolchain/linux:clang_x86_v8_arm\""
            ;;
          arm64)
            echo "v8_snapshot_toolchain = \"//build/toolchain/linux:clang_x64_v8_arm64\""
            ;;
          *)
            echo "v8_snapshot_toolchain = \"//build/toolchain/linux:$TARGET_CPU\""
            ;;
        esac
      fi
      ;;
  esac

) | sort > "$BUILD/args.gn"

# Generate Ninja files
pushd "$SOURCE"
gn gen "$BUILD"
popd
