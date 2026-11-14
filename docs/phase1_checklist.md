# Phase I submission checklist

Scope: the confirmed **four-member** group; video excluded from this task.

| Requirement | Included evidence |
|---|---|
| IEEE-format report | report/Phase_I_IEEE_Report.pdf, built with IEEEtran conference class |
| Abstract | Report abstract |
| Literature Review | Report Section II with numbered primary-source references |
| Proposed Solution | Report Section III, architecture and host/control explanation |
| Individual Contributions | Report Section V and README, four members |
| References | Five numbered references in the report |
| Modular RTL | rtl/ with ALU, storage, control, SIMD and scalar designs |
| Prototype verification | Six self-checking benches, CI logs, directed/pseudorandom tests |
| Architecture and state description | docs/architecture.md and docs/proposed_solution.md |
| Waveform evidence | Actual VCD files plus rendered ADD trace and interpretation |
| Quantitative comparison | CSV benchmark: 47 vs 95 periods per 16-vector resident batch |
| Synthesis and internal clock results | Actual mapped cells and routed timing in evidence/results.json |
| Reproducibility | Simulation/build scripts, tool versions, logs and editable report source |
| Video | Excluded; the video and its final accessible link remain separate deliverables |

## Scope and remaining actions

- Review the report's four author names before submission. Abhay is listed using the name supplied; no surname, roll number or affiliation has been invented.
- The original notice mentions five members; this package follows the user's explicit four-member group instruction.
- No video URL has been invented, and the submission form has not been filled or submitted.
- FPGA results use a declared device/package and automatic pin placement, not a physical board. External I/O timing and board demonstration are not claimed.
- Existing commit attribution has been preserved. Aditya's named commit remains unlinked to a GitHub profile; no historical authorship was rewritten.
