import numpy as np

# Parameters
N = 256  # Frame size
Q = 15  # Fixed-point precision

# Hanning window formula: w(n) = 0.5 * (1 - cos(2 * pi * n / (N - 1)))
hanning_coeff = [0] * N
for n in range(N):
    w = 0.5 * (1 - np.cos(2 * np.pi * n / (N - 1)))
    fixed_point_value = int(round(w * (1 << Q)))
    hanning_coeff[n] = fixed_point_value

# Printing the coefficients in the required Verilog format
print("localparam [15:0] HANNING_COEFF_REAL [0:{}] = {{".format(N-1))
for i, coeff in enumerate(hanning_coeff):
    if i % 8 == 0 and i != 0:
        print()
    print("16'h{:04X}".format(coeff & 0xFFFF), end=', ' if i < N-1 else ' ')
print("};")
