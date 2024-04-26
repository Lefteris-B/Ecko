import math

# Configuration
NUM_COEFFS = 32

# Function to compute DCT coefficients
def dct_coeff(k, n, N):
    if k == 0:
        return math.sqrt(1 / N)
    else:
        return math.sqrt(2 / N) * math.cos((math.pi * (2 * n + 1) * k) / (2 * N))

# Generate DCT coefficients
dct_coeffs = []
for k in range(NUM_COEFFS):
    row_coeffs = []
    for n in range(NUM_COEFFS):
        coeff_value = dct_coeff(k, n, NUM_COEFFS)
        coeff_fixed_point = int(coeff_value * (2 ** 30))  # Assuming Q2.30 format
        if coeff_fixed_point < 0:
            coeff_fixed_point = (1 << 32) + coeff_fixed_point  # Convert negative values to unsigned representation
        row_coeffs.append(coeff_fixed_point)
    dct_coeffs.append(row_coeffs)

# Generate Verilog code for DCT coefficient initialization
print("// Initialize DCT coefficients")
for k in range(NUM_COEFFS):
    for n in range(NUM_COEFFS):
        print(f"dct_coeffs[{k}][{n}] = 32'h{dct_coeffs[k][n]:08X};")