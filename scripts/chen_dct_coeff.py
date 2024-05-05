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

# Print the coefficients in Verilog format
for k in range(N):
    coeff_str = ', '.join([f"{coeff:#06x}" for coeff in dct_coefficients[k]])
    print(f"{k}: coeff = (input_counter == 0) ? {dct_coefficients[k][0]:#06x} : (input_counter == 1) ? {dct_coefficients[k][1]:#06x} : (input_counter == 2) ? {dct_coefficients[k][2]:#06x} : (input_counter == 3) ? {dct_coefficients[k][3]:#06x} : (input_counter == 4) ? {dct_coefficients[k][4]:#06x} : (input_counter == 5) ? {dct_coefficients[k][5]:#06x} : (input_counter == 6) ? {dct_coefficients[k][6]:#06x} : (input_counter == 7) ? {dct_coefficients[k][7]:#06x} : (input_counter == 8) ? {dct_coefficients[k][8]:#06x} : (input_counter == 9) ? {dct_coefficients[k][9]:#06x} : (input_counter == 10) ? {dct_coefficients[k][10]:#06x} : (input_counter == 11) ? {dct_coefficients[k][11]:#06x} : (input_counter == 12) ? {dct_coefficients[k][12]:#06x} : (input_counter == 13) ? {dct_coefficients[k][13]:#06x} : (input_counter == 14) ? {dct_coefficients[k][14]:#06x} : (input_counter == 15) ? {dct_coefficients[k][15]:#06x} : (input_counter == 16) ? {dct_coefficients[k][16]:#06x} : (input_counter == 17) ? {dct_coefficients[k][17]:#06x} : (input_counter == 18) ? {dct_coefficients[k][18]:#06x} : (input_counter == 19) ? {dct_coefficients[k][19]:#06x} : (input_counter == 20) ? {dct_coefficients[k][20]:#06x} : (input_counter == 21) ? {dct_coefficients[k][21]:#06x} : (input_counter == 22) ? {dct_coefficients[k][22]:#06x} : (input_counter == 23) ? {dct_coefficients[k][23]:#06x} : (input_counter == 24) ? {dct_coefficients[k][24]:#06x} : (input_counter == 25) ? {dct_coefficients[k][25]:#06x} : (input_counter == 26) ? {dct_coefficients[k][26]:#06x} : (input_counter == 27) ? {dct_coefficients[k][27]:#06x} : (input_counter == 28) ? {dct_coefficients[k][28]:#06x} : (input_counter == 29) ? {dct_coefficients[k][29]:#06x} : (input_counter == 30) ? {dct_coefficients[k][30]:#06x} : {dct_coefficients[k][31]:#06x};")