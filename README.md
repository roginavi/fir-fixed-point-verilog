# Fixed-point FIR filter: Python golden model + Verilog RTL

A 4-tap low-pass FIR filter taken from algorithm to hardware description, verified bit-exact against a software model.

## Flow
1. `fir_model.py` designs the filter, quantizes coefficients to Q1.15, runs a 16-bit integer model on a noisy 5 Hz test signal, and writes `input.hex` / `expected.hex`.
2. `fir4.v` is the RTL: delay line, four 16x16 multipliers, 32-bit accumulator, arithmetic shift back to Q1.15, registered output.
3. `fir4_tb.v` is a self-checking testbench: it replays `input.hex` and compares every output to `expected.hex`.

## Run
```
pip install numpy
python3 fir_model.py                 # generates input.hex, expected.hex
iverilog -o sim fir4.v fir4_tb.v
vvp sim                              # prints PASS or the mismatches
gtkwave fir4.vcd                     # optional: inspect waveforms
```

## Results
- Q1.15 coefficients: 3277, 13107, 13107, 3277
- Max error vs floating point: 1 LSB
- Quantization SNR: 85.6 dB
- RTL vs golden model: 256/256 samples match

## Design notes
- Sum of |coefficients| = 1.0, so the 32-bit accumulator cannot overflow.
- Output truncates (floor) via `>>>`; Python's `>>` on integers behaves the same, which keeps the model bit-exact.
- Output is registered: y[n] appears one clock after x[n].

## Ideas to extend
- Symmetric-coefficient optimization (2 multipliers instead of 4)
- Pipeline the adder tree and compare timing
- Parameterize taps and bit widths
- Replace with the Pan-Tompkins bandpass for ECG on MIT-BIH data
- Synthesize with Yosys or Vivado and report resource use and Fmax
