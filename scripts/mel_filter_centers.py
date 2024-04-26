import numpy as np

# Configuration
NUM_MEL_FILTERS = 40
SAMPLE_RATE = 16000
FFT_SIZE = 256

# Mel-scale parameters
MEL_LOW_FREQ = 0
MEL_HIGH_FREQ = 2595 * np.log10(1 + SAMPLE_RATE / 2 / 700)
MEL_POINTS = np.linspace(MEL_LOW_FREQ, MEL_HIGH_FREQ, NUM_MEL_FILTERS + 2)
HZ_POINTS = 700 * (10 ** (MEL_POINTS / 2595) - 1)

# Compute mel-scale filter center frequencies
mel_filter_centers = np.floor((FFT_SIZE + 1) * HZ_POINTS / SAMPLE_RATE).astype(int)

# Generate Verilog code for mel-scale filter center frequencies initialization
print("// Initialize mel-scale filter center frequencies")
print("initial begin")
for i in range(NUM_MEL_FILTERS + 1):
    print(f"    mel_filter_centers[{i}] = 8'd{mel_filter_centers[i]};")
print("end")