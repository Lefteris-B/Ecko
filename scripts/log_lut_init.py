import math

# Configuration
LUT_SIZE = 1024
LUT_DATA_WIDTH = 16
INPUT_RANGE = (0, 10)  # Range of input values for logarithm computation

# Function to convert floating-point value to fixed-point representation
def to_fixed_point(value, width):
    return int(round(value * (2 ** (width - 1))))

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
    print(f"    log_lut[{i}] = {LUT_DATA_WIDTH}'h{log_lut[i]:04X};")
print("end")