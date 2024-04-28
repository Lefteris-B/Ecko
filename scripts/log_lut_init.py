import math

# Configuration
LUT_SIZE = 1024
LUT_DATA_WIDTH = 16
INPUT_RANGE = (0, 10)  # Range of input values for logarithm computation

# Function to convert floating-point value to fixed-point representation
def to_fixed_point(value, width):
    if value >= 0:
        return int(round(value * (2 ** (width - 1))))
    else:
        return int(round((2 ** width) + (value * (2 ** (width - 1))))) & ((2 ** width) - 1)

# Generate logarithm lookup table
log_lut = []
for i in range(LUT_SIZE):
    # Map LUT index to input value
    input_value = INPUT_RANGE[0] + (INPUT_RANGE[1] - INPUT_RANGE[0]) * i / (LUT_SIZE - 1)
    
    # Compute logarithm value
    if input_value <= 0:
        log_value = 0
    else:
        log_value = math.log(input_value)
    
    # Convert logarithm value to fixed-point representation
    log_fixed_point = to_fixed_point(log_value, LUT_DATA_WIDTH)
    
    # Append to lookup table
    log_lut.append(log_fixed_point)

# Generate Verilog code for logarithm lookup table initialization
print("// Initialize logarithm lookup table")
print("initial begin")
for i in range(LUT_SIZE):
    hex_value = f"{log_lut[i] & 0xFFFF:04X}"  # Truncate to 16 bits and format as 4-digit hexadecimal
    print(f"    log_lut[{i}] = 16'h{hex_value};")
print("end")