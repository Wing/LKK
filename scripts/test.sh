#!/bin/bash
source "$(dirname "$0")/common.sh"
"$CXX" "${FLAGS[@]}" Sources/ModelTool.cpp "${SOURCES[@]}" -lsqlite3 -o build/modeltool
"$CXX" "${FLAGS[@]}" Tests/EngineTests.cpp "${SOURCES[@]}" -lsqlite3 -o build/engine-tests
python3 scripts/build-model.py --fixture
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
build/engine-tests build/fixture.db "$TEST_DIR/user.db"
python3 scripts/audit.py
