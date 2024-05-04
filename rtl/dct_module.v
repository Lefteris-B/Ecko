module dct_module #(
    parameter NUM_LOG_MELS = 40,
    parameter LOG_MEL_WIDTH = 16,
    parameter NUM_MFCC_COEFS = 13,
    parameter MFCC_COEF_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [LOG_MEL_WIDTH-1:0] log_mel_energies [0:NUM_LOG_MELS-1],
    output wire [MFCC_COEF_WIDTH-1:0] mfcc_coefs [0:NUM_MFCC_COEFS-1]
);

// Fixed-point parameters
localparam FP_FRAC_BITS = 10;
localparam FP_INT_BITS = LOG_MEL_WIDTH - FP_FRAC_BITS;
localparam PI = 3.14159265358979323846;

// Intermediate registers
reg [LOG_MEL_WIDTH-1:0] log_mel_energies_reg [0:NUM_LOG_MELS-1];
reg [MFCC_COEF_WIDTH-1:0] mfcc_coefs_reg [0:NUM_MFCC_COEFS-1];

// Register inputs
always @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_LOG_MELS; i = i + 1) begin
            log_mel_energies_reg[i] <= 0;
        end
    end else begin
        log_mel_energies_reg <= log_mel_energies;
    end
end

// Function to compute the polynomial approximation of cosine
function [MFCC_COEF_WIDTH-1:0] cos_approx;
    input [MFCC_COEF_WIDTH-1:0] x;
    reg [MFCC_COEF_WIDTH-1:0] x_sq;
    reg [MFCC_COEF_WIDTH-1:0] result;
begin
    x_sq = (x * x) >>> FP_FRAC_BITS;
    result = (1 << FP_FRAC_BITS) - (x_sq >> 1) + ((x_sq * x_sq) >>> (4 * FP_FRAC_BITS));
    cos_approx = result;
end
endfunction

// DCT computation using polynomial approximation
generate
    for (genvar k = 0; k < NUM_MFCC_COEFS; k = k + 1) begin
        always @(posedge clk) begin
            if (rst) begin
                mfcc_coefs_reg[k] <= 0;
            end else begin
                reg [MFCC_COEF_WIDTH-1:0] sum;
                sum = 0;
                for (int n = 0; n < NUM_LOG_MELS; n = n + 1) begin
                    // Compute the argument for the cosine function
                    reg [MFCC_COEF_WIDTH-1:0] arg;
                    arg = (PI * k * (2 * n + 1)) / (2 * NUM_LOG_MELS);
                    
                    // Compute the cosine approximation
                    reg [MFCC_COEF_WIDTH-1:0] cos_val;
                    cos_val = cos_approx(arg);
                    
                    // Multiply and accumulate
                    sum = sum + (log_mel_energies_reg[n] * cos_val);
                end
                mfcc_coefs_reg[k] <= sum >>> FP_FRAC_BITS;
            end
        end
    end
endgenerate

// Register outputs
assign mfcc_coefs = mfcc_coefs_reg;

endmodule