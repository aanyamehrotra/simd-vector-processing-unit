#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build evidence report/preview
for unit in alu_lane vector_control vector_regfile simd_top scalar_top performance; do
  iverilog -g2012 -Wall -s "tb_$unit" -o "build/$unit.vvp" rtl/*.v "tb/tb_$unit.v"
  vvp "build/$unit.vvp" | tee "build/$unit.log"
  grep -q PASS "build/$unit.log"
  if grep -q FAIL "build/$unit.log"; then exit 1; fi
done
for top in simd_top scalar_top; do
  yosys -p "read_verilog rtl/alu_lane.v rtl/vector_regfile.v rtl/vector_control.v rtl/simd_top.v rtl/scalar_top.v; synth_ice40 -top $top -json build/$top.json; check; stat" >"build/$top"_synth.log 2>&1
  nextpnr-ice40 --hx8k --package ct256 --seed 1 --freq 25 --pcf-allow-unconstrained --json "build/$top.json" --asc "build/$top.asc" >"build/$top"_pnr.log 2>&1
done
{ iverilog -V; yosys -V; nextpnr-ice40 --version; pdflatex --version; } >evidence/tool_versions.log 2>&1
python3 scripts/collect_evidence.py
rsvg-convert -f pdf -o evidence/simd_add_waveform.pdf evidence/simd_add_waveform.svg
rsvg-convert -f png -o evidence/simd_add_waveform.png evidence/simd_add_waveform.svg
cd report
pdflatex -halt-on-error -interaction=nonstopmode main.tex >../build/report_compile.log
pdflatex -halt-on-error -interaction=nonstopmode main.tex >>../build/report_compile.log
cp main.pdf Phase_I_IEEE_Report.pdf
pdftoppm -r 72 -gray -png main.pdf preview/page
pdftotext main.pdf ../build/report_text.txt
if grep -q "Overfull" main.log; then grep "Overfull" main.log; exit 1; fi
cd ..
python3 - <<'PY'
from pathlib import Path
import re
text=re.sub('[^A-Z]', '', Path('build/report_text.txt').read_text().upper())
for section in ['Abstract','LITERATURE REVIEW','PROPOSED SOLUTION','INDIVIDUAL CONTRIBUTIONS','REFERENCES']:
    assert re.sub('[^A-Z]', '', section.upper()) in text,section
assert all(name.upper() in text for name in ['Abhay','Aditya','Aanya','Vachan'])
print('PASS report section and author validation')
PY
