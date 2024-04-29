import math

# Number of points in the cosine lookup table
TABLE_SIZE = 256

# Generate the cosine lookup table initialization code
print("initial begin")
for i in range(TABLE_SIZE):
    # Calculate the cosine value
    angle = 2 * math.pi * i / TABLE_SIZE
    cosine = math.cos(angle)
    
    # Convert the cosine value to Q15 format
    q15_cosine = round(cosine * (2**15 - 1))
    
    # Print the initialization code
    print(f"    cos_table[{i}] = 16'h{q15_cosine & 0xFFFF:04X};")
print("end")