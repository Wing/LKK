#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
SDK=$(xcrun --sdk macosx --show-sdk-path)
CXX=$(xcrun --find clang++)
FLAGS=(-std=c++17 -arch arm64 -mmacosx-version-min=14.0 -isysroot "$SDK" -isystem "$SDK/usr/include/c++/v1" -Wno-parentheses -Wno-extra-tokens -I vendor -I vendor/Manjusri -I vendor/Formosa -I Sources)
SOURCES=(vendor/Formosa/Mandarin.cpp vendor/Manjusri/Node.cpp)
mkdir -p build
