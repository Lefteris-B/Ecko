module hanning_window (
    input wire clk,
    input wire rst,
    input wire signed [15:0] sample_in, // INT16 Q15
    input wire sample_valid,
    output reg signed [15:0] sample_out_real, // INT16 Q15
    output reg signed [15:0] sample_out_imag, // INT16 Q15
    output reg sample_out_valid
);

localparam N = 256; // Frame size
localparam Q = 15; // Fixed-point precision
localparam NF = 512; // Power-of-two size for zero-padding

reg signed [15:0] sample_buffer [0:N-1]; // INT16 Q15
reg [$clog2(NF)-1:0] sample_count;
reg [$clog2(N)-1:0] coeff_count;
reg signed [15:0] coeff; // INT16 Q15

// Fixed-point constants
localparam signed [15:0] CONST_05 = 16'h4000; // 0.5 in Q15
localparam signed [15:0] CONST_2PI = 16'h6487; // 2π in Q15

// CORDIC approximation of cosine
function signed [15:0] cordic_cos;
    input signed [15:0] angle;
    reg signed [15:0] x, y, z;
    reg [3:0] i;
begin
    x = 16'h4DBA; // 0.607252935 in Q15
    y = 0;
    z = angle;

    for (i = 0; i < 12; i = i + 1) begin
        if (z[15] == 1) begin
            x = x - (y >> i);
            y = y + (x >> i);
            z = z + cordic_atan_table[i];
        end else begin
            x = x + (y >> i);
            y = y - (x >> i);
            z = z - cordic_atan_table[i];
        end
    end

    cordic_cos = x;
end
endfunction

// CORDIC arctangent table (Q15)
localparam signed [15:0] cordic_atan_table [0:11] = {
    16'h3243, 16'h1DAC, 16'h0FAD, 16'h07F5,
    16'h03FE, 16'h01FF, 16'h0100, 16'h0080,
    16'h0040, 16'h0020, 16'h0010, 16'h0008
};

always @(posedge clk) begin
    if (rst) begin
        sample_count <= 0;
        coeff_count <= 0;
        sample_out_valid <= 0;
        sample_out_real <= 0;
        sample_out_imag <= 0;
    end else begin
        if (sample_valid) begin
            sample_buffer[sample_count] <= sample_in;
            sample_count <= (sample_count == N-1) ? 0 : sample_count + 1;

            if (sample_count == N-1) begin
                coeff_count <= 0;
                sample_out_valid <= 1;
            end
        end else if (coeff_count < N) begin
            coeff = CONST_05 - (CONST_05 * cordic_cos((CONST_2PI * coeff_count) / N)) >> Q;
            sample_out_real <= (sample_buffer[coeff_count] * coeff) >> Q;
            sample_out_imag <= 0; // Hanning window is a real-valued function
            coeff_count <= coeff_count + 1;
        end else if (coeff_count < NF) begin
            sample_out_real <= 0; // Zero-padding
            sample_out_imag <= 0; // Zero-padding
            coeff_count <= coeff_count + 1;
        end else begin
            sample_out_valid <= 0;
        end
    end
end

endmodule
