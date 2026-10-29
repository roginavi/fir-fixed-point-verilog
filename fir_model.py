"""Golden model: 4-tap FIR low-pass filter, float vs 16-bit fixed-point (Q1.15).

Generates input.hex / expected.hex for the Verilog testbench.
"""
import numpy as np

N = 256
COEF_FLOAT = np.array([0.1, 0.4, 0.4, 0.1])
COEF_Q15 = np.round(COEF_FLOAT * 2**15).astype(np.int64)  # [3277, 13107, 13107, 3277]

# Test signal: 5 Hz "physiological" sine + high-frequency noise (fs = 250 Hz)
rng = np.random.default_rng(0)
t = np.arange(N) / 250
x_float = 0.5 * np.sin(2 * np.pi * 5 * t) + 0.1 * rng.standard_normal(N)
x_q15 = np.clip(np.round(x_float * 2**15), -32768, 32767).astype(np.int64)  # int16 input


def fir_fixed(x, c):
    """y[n] = (sum_k c[k]*x[n-k]) >> 15, integer arithmetic, zero initial state."""
    y = np.zeros(len(x), dtype=np.int64)
    for n in range(len(x)):
        acc = 0
        for k, ck in enumerate(c):
            if n - k >= 0:
                acc += int(ck) * int(x[n - k])
        y[n] = acc >> 15  # arithmetic shift = floor, same as Verilog >>>
    return y


y_fixed = fir_fixed(x_q15, COEF_Q15)
y_float = np.convolve(x_q15, COEF_FLOAT)[:N]

err = y_fixed - y_float
snr = 10 * np.log10(np.sum(y_float**2) / np.sum(err**2))
print(f"Coefficients Q1.15: {COEF_Q15.tolist()}")
print(f"Max abs error vs float: {np.max(np.abs(err)):.2f} LSB")
print(f"Quantization SNR: {snr:.1f} dB")


def write_hex(name, data):
    with open(name, "w") as f:
        for v in data:
            f.write(f"{int(v) & 0xFFFF:04x}\n")  # two's complement, 16 bit


write_hex("input.hex", x_q15)
write_hex("expected.hex", y_fixed)
print("Wrote input.hex and expected.hex")
