# SIMD Vector Processing Unit

Four parallel 8-bit lanes execute a shared operation on 32-bit vectors. The project includes a one-ALU scalar baseline, six self-checking testbenches, an IEEE conference-format Phase I report and reproducible FPGA evaluation.

## Phase I submission

- [IEEE project report (PDF)](report/Phase_I_IEEE_Report.pdf)
- [Editable IEEEtran LaTeX source](report/main.tex)
- [Architecture and host interface](docs/architecture.md)
- [Microarchitecture and timing](docs/proposed_solution.md)
- [Measured scalar comparison](docs/performance.md)
- [Waveform verification](docs/waveform_verification.md)
- [Synthesis and routed timing evidence](evidence/results.json)
- [Phase I checklist](docs/phase1_checklist.md)
- [Automated builds](https://github.com/aanyamehrotra/simd-vector-processing-unit/actions)

The video is excluded from this preparation task. No video link has been invented or submitted. The confirmed project group has **four members**; the supplied evaluation notice refers to five, so the submitted group size should follow the instructor's applicable arrangement.

## Architecture

- Four vector registers, each 32 bits wide.
- Four physical 8-bit ALUs in the SIMD unit; one reused ALU in the scalar baseline.
- Two combinational register reads and one synchronous write.
- Captured operands, opcode and destination; rising-edge synchronous reset.
- Lane 0 occupies bits [7:0], lane 3 bits [31:24].
- ADD, SUB, AND, OR and unsigned less-than; reserved opcodes return zero.
- Arithmetic wraps per byte without carry between lanes.
- Host load/inspection interface and start/busy/done handshake.

See [the complete block diagram](docs/architecture.md). Result packing is wiring and lane selection is implemented with vector slices.

## Run simulation

Install Icarus Verilog and a Bash shell. From the repository root:

~~~sh
bash scripts/run_simulation.sh
~~~

Expected results: all six benches print PASS; ALU 524,317 checks, SIMD 1,678 checks, scalar 2,503 checks; 25 matched benchmark batches covering 400 vectors per architecture. Results and logs are written under build/; the benchmark also emits performance.csv. VCD files can be opened in GTKWave.

## Performance

For each matched batch of 16 resident-vector instructions (64 element operations):

| Metric | SIMD | Scalar |
|---|---:|---:|
| Acceptance-to-completion latency | 2 clock periods | 5 clock periods |
| Minimum initiation interval | 3 clock periods | 6 clock periods |
| Batch time | 47 clock periods | 95 clock periods |
| Steady-state element operations/clock | 4/3 | 4/6 |

Measured compute batch speed-up is **95/47 = 2.021277x**, excluding loading, inspection and external memory. Single-instruction latency improvement is 2.5x. These are separate metrics; four lanes do not imply a measured 4x application speed-up.

## Rebuild the report and FPGA evidence

The Phase I workflow installs the required tools and runs:

~~~sh
bash scripts/build_phase1.sh
~~~

Local dependencies: Icarus Verilog, Yosys, nextpnr-ice40, the IceStorm device database, Python 3, pdfLaTeX with IEEEtran and TikZ, Poppler and librsvg. Ubuntu package names are listed in [.github/workflows/phase1.yml](.github/workflows/phase1.yml).

Both designs target **Lattice iCE40 HX8K, CT256, seed 1**, with a 25 MHz requested clock. Pins are placed automatically and external input/output delay constraints are not supplied. Reported frequency is a routed **internal clock estimate**, not board timing signoff. This project has not been demonstrated on physical FPGA hardware.

Measured mapped resources and routed internal timing from the recorded build:

| Metric | SIMD | Scalar |
|---|---:|---:|
| LUT4 cells | 427 | 347 |
| Flip-flop cells | 201 | 234 |
| Carry cells | 88 | 23 |
| Block RAM cells | 0 | 0 |
| Routed internal clock limit (MHz) | 114.10 | 82.86 |

The committed evidence is a snapshot of a recorded build. Rebuilding can change tool-dependent resource/timing results; use evidence/tool_versions.log, the raw synthesis/place-and-route logs and evidence/results.json to interpret it. The report's FPGA table is generated from those measured outputs.

## Files

| Path | Purpose |
|---|---|
| rtl/ | Five modules: lane ALU, vector storage/control, SIMD and scalar top levels |
| tb/ | Six self-checking component, integration and performance benches |
| scripts/run_simulation.sh | Reproducible simulation commands |
| scripts/build_phase1.sh | Full simulation, synthesis, routing and report build |
| scripts/collect_evidence.py | Parse actual VCD/netlists/timing logs into figures and metrics |
| report/ | IEEE report PDF, source and measured table |
| evidence/ | VCD traces, logs, benchmark CSV, waveform image and measured JSON |
| docs/ | Architecture, protocol, verification, performance and submission notes |

## Four-member contribution record

| Member | Recorded implementation area |
|---|---|
| Vachan Gupta | ALU lane and directed/exhaustive verification |
| Aditya Srivastava | Register file, controller and component tests |
| Aanya Mehrotra | SIMD integration, integrated tests, architecture and Phase I packaging |
| Abhay (Bhshdhhhd) | Scalar baseline, tests, comparison benchmark and CI extension |

ChatGPT assistance is recorded for integration, baseline development, testing and documentation. GitHub commit attribution and the technical contribution summary are retained. Aditya's existing commit records his name but is not linked to a GitHub account; history has not been rewritten to manufacture attribution.

## Scope

The design does not include instruction fetch, caches, masking, signed comparisons, shifts or multiplication. The optional operations are not necessary for the stated core project. Hardware programming and board-specific I/O constraints remain future work. The report makes no power or physical-board performance claim.
