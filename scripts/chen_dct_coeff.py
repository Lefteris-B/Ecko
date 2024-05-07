import math

def chen_dct_coeff(k, n, N):
    if k == 0:
        return math.sqrt(1/N)
    else:
        return math.sqrt(2/N) * math.cos(math.pi * (2*n + 1) * k / (2*N))

def fixed_point_coeff(coeff, precision):
    return round(coeff * (2**precision))

def generate_dct_coefficients(N, precision):
    coefficients = []
    for k in range(N):
        coeff_row = []
        for n in range(N):
            coeff = chen_dct_coeff(k, n, N)
            fixed_coeff = fixed_point_coeff(coeff, precision)
            coeff_row.append(fixed_coeff)
        coefficients.append(coeff_row)
    return coefficients

# Set the DCT size and fixed-point precision
N = 32
precision = 15

# Generate the fixed-point DCT coefficients
dct_coefficients = generate_dct_coefficients(N, precision)

# Print the coefficients in Verilog format for the refactored case statement
for k in range(N):
    for n in range(N):
        coeff = dct_coefficients[k][n]
        if coeff != 0:
            print(f"      {{5'd{k}, 5'd{n}}}: coeff = {coeff:#06x};")

print("      default: coeff = 16'h0000;")