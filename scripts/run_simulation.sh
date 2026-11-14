#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
for unit in alu_lane vector_control vector_regfile simd_top scalar_top performance; do
  iverilog -g2012 -Wall -s "tb_$unit" -o "build/$unit.vvp" rtl/*.v "tb/tb_$unit.v"
  vvp "build/$unit.vvp" | tee "build/$unit.log"
  grep -q PASS "build/$unit.log"
  if grep -q FAIL "build/$unit.log"; then exit 1; fi
done
