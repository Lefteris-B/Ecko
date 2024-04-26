import math

def hamming_window(n, N):
    return 0.54 - 0.46 * math.cos((2 * math.pi * n) / (N - 1))

def fixed_point_q15(value):
    return int(round(value * (2**15)))

def generate_verilog_lookup_table(window_size):
    lookup_table = []
    for i in range(window_size):
        coeff = hamming_window(i, window_size)
        lookup_table.append(fixed_point_q15(coeff))

    verilog_code = "reg [15:0] cos_table [0:{}] = {{\n".format(window_size - 1)
    for i in range(0, window_size, 8):
        verilog_code += "    "
        for j in range(8):
            if i + j < window_size:
                verilog_code += "16'h{:04X}".format(lookup_table[i + j])
                if i + j < window_size - 1:
                    verilog_code += ", "
        verilog_code += "\n"
    verilog_code += "};\n"
    return verilog_code

# Example usage
window_size = 256
verilog_lookup_table = generate_verilog_lookup_table(window_size)

print("Verilog code for the cosine lookup table:")
print(verilog_lookup_table)