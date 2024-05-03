import numpy as np
import math

# Mel-scale filterbank parameters
NUM_MEL_FILTERS = 40
NUM_DFT_POINTS = 256
SAMPLE_RATE = 16000  # Assuming a sample rate of 16 kHz
LOW_FREQ_MEL = 0
HIGH_FREQ_MEL = 2595 * np.log10(1 + (SAMPLE_RATE / 2) / 700)  # Convert Hz to Mel

# Generate mel-scale filter center frequencies
mel_filter_centers = np.linspace(LOW_FREQ_MEL, HIGH_FREQ_MEL, NUM_MEL_FILTERS + 2)

# Convert mel-scale filter center frequencies to linear scale
linear_filter_centers = 700 * (10 ** (mel_filter_centers / 2595) - 1)

# Compute the DFT bin frequencies
dft_bin_freqs = np.arange(NUM_DFT_POINTS) * (SAMPLE_RATE / 2) / (NUM_DFT_POINTS - 1)

# Initialize the mel-scale filter coefficients
mel_filter_coefs = np.zeros((NUM_MEL_FILTERS, NUM_DFT_POINTS))

# Compute the mel-scale filter coefficients
for m in range(1, NUM_MEL_FILTERS + 1):
    left_freq = linear_filter_centers[m - 1]
    center_freq = linear_filter_centers[m]
    right_freq = linear_filter_centers[m + 1]

    for k in range(NUM_DFT_POINTS):
        if dft_bin_freqs[k] >= left_freq and dft_bin_freqs[k] <= center_freq:
            mel_filter_coefs[m - 1, k] = (dft_bin_freqs[k] - left_freq) / (center_freq - left_freq)
        elif dft_bin_freqs[k] > center_freq and dft_bin_freqs[k] <= right_freq:
            mel_filter_coefs[m - 1, k] = (right_freq - dft_bin_freqs[k]) / (right_freq - center_freq)

# Scale the filter coefficients to a fixed-point representation (Q15 format)
Q15_SCALE = 2 ** 15
mel_filter_coefs_fixed = np.round(mel_filter_coefs * Q15_SCALE).astype(int)

# Generate Verilog code for the mel-scale filter coefficients
verilog_code = ""
for m in range(NUM_MEL_FILTERS):
    for k in range(NUM_DFT_POINTS):
        verilog_code += f"mel_filter_coefs[{m}][{k}] = 16'h{mel_filter_coefs_fixed[m, k]:04X};\n"

# Print the Verilog code
print(verilog_code)