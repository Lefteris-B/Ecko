import numpy as np

# Configuration
num_mel_filters = 40
dft_size = 256
sample_rate = 16000
lower_freq = 0
upper_freq = sample_rate // 2

# Mel-scale parameters
mel_low_freq = 0
mel_high_freq = 2595 * np.log10(1 + upper_freq / 700)
mel_points = np.linspace(mel_low_freq, mel_high_freq, num_mel_filters + 2)
hz_points = 700 * (10**(mel_points / 2595) - 1)

# Compute mel-scale filter center frequencies
mel_filter_centers = np.floor((dft_size + 1) * hz_points / sample_rate).astype(int)

# Compute mel-scale filter coefficients
mel_filter_coefs = np.zeros((num_mel_filters, dft_size))

for i in range(num_mel_filters):
    left_idx = mel_filter_centers[i]
    center_idx = mel_filter_centers[i + 1]
    right_idx = mel_filter_centers[i + 2]

    for j in range(left_idx, center_idx):
        mel_filter_coefs[i, j] = (j - left_idx) / (center_idx - left_idx)

    for j in range(center_idx, right_idx):
        mel_filter_coefs[i, j] = (right_idx - j) / (right_idx - center_idx)

# Convert mel-scale filter coefficients to fixed-point representation (Q15 format)
q15_scale = 2**15 - 1
mel_filter_coefs_q15 = (mel_filter_coefs * q15_scale).astype(int)

# Generate Verilog code for mel-scale filter coefficients
print("// Mel-scale filter coefficients")
for i in range(num_mel_filters):
    print(f"mel_filter_coefs[{i}] = ", end="")
    print("{", end="")
    for j in range(dft_size):
        print(f"{mel_filter_coefs_q15[i, j]}", end="")
        if j < dft_size - 1:
            print(", ", end="")
    print("};")

# Generate Verilog code for mel-scale filter center frequencies
print("\n// Mel-scale filter center frequencies")
print("mel_filter_centers = ", end="")
print("{", end="")
for i in range(num_mel_filters):
    print(f"{mel_filter_centers[i + 1]}", end="")
    if i < num_mel_filters - 1:
        print(", ", end="")
print("};")