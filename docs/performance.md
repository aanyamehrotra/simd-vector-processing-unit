# Scalar baseline and measured SIMD comparison

## Implementation

The scalar baseline instantiates one shared 8-bit ALU and processes byte indices 0 through 3 sequentially. It uses the same four-register vector store, operations, host protocol and operand capture semantics as the SIMD unit. In-place destinations are supported. Host writes and start requests while busy are discarded. Synchronous reset clears storage and cancels work.

At E0 an instruction is accepted. E1 through E4 collect the four scalar element results. E5 writes the complete vector and pulses done. The next instruction can be accepted at E6. The SIMD schedule accepts at E0, writes at E2 and accepts the next instruction at E3.

## Measured simulation results

[Icarus Verilog simulation run](https://github.com/Bhshdhhhd/simd-vector-processing-unit/actions/runs/43616437411) passed all six testbenches. The scalar testbench passed 2,503 checks. The benchmark validated 25 batches: five operand pairs (one directed, four pseudorandom), each exercised with ADD, SUB, AND, OR and unsigned less-than. Each batch contains 16 vector instructions (64 element operations), giving 400 vectors per architecture overall. Every completed vector is checked against an independent testbench model.

| Metric | SIMD | Scalar |
|---|---:|---:|
| Physical ALU instances | 4 | 1 |
| Acceptance-to-completion latency, clock periods | 2 | 5 |
| Minimum initiation interval, clock periods | 3 | 6 |
| Elapsed cycles for a 16-vector resident batch | 47 | 95 |
| Element operations per cycle in that batch | 64/47 = 1.3617 | 64/95 = 0.6737 |
| Steady-state element operations per clock | 4/3 | 4/6 |

For all five operations, measured finite-batch speed-up is 95/47 = **2.021277x**. Single-instruction latency improves by 5/2 = **2.5x**. Sustained compute throughput tends to **2x** for large batches. These are different metrics and should not be substituted for one another.

Timing counts rising-edge intervals from first request acceptance to final completion: for N vectors, SIMD takes 3N-1 periods and scalar takes 6N-1. This excludes any interval before the first acceptance and after the last completion, explaining why finite-batch rates can slightly exceed the steady-state rates. All workloads use preloaded source registers and independent destinations. Host loading, inspection, external memory and software overhead are excluded.

The result is specific to these two controllers at the same simulated clock period. It is not an FPGA frequency, power, area or end-to-end application claim. The scalar baseline includes operand capture and vector writeback overhead and is not claimed to be an optimized scalar CPU. Target-specific synthesis and routed internal clock estimates are now recorded in
[results.json](../evidence/results.json) and the [IEEE report](../report/Phase_I_IEEE_Report.pdf).
They use iCE40 HX8K/CT256, seed 1 and a 25 MHz requested clock, with automatic
pin placement and no external I/O delay constraints. Physical-board demonstration
and board-level timing signoff remain outside this result.

## Reproduction

Install Icarus Verilog and run from the repository root:

~~~sh
mkdir -p build
for unit in alu_lane vector_control vector_regfile simd_top scalar_top performance; do
  iverilog -g2012 -Wall -s tb_$unit -o build/$unit.vvp rtl/*.v tb/tb_$unit.v
  vvp build/$unit.vvp
 done
~~~

The benchmark writes performance.csv with per-trial opcode, vector count, latencies, batch cycles, element count and speed-up. GitHub Actions retains that CSV, test logs and VCD waveforms in its simulation-evidence artifact. For waveform inspection, open tb_performance.vcd or tb_scalar_top.vcd in GTKWave. Dumping is limited to initial directed work; assertions continue throughout the random tests.

## Contribution record

This scalar baseline, testbench, benchmark and workflow extension were prepared with ChatGPT assistance and published through Abhay's account with authorization. The report records four members and the implementation areas associated with their commits; AI assistance is disclosed.
