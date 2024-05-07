`ifndef DCT_COMP_V
`define DCT_COMP_V

module dct_comp #(
    parameter MFCC_FEATURES = 40,
    parameter ACTIV_BITS = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [31:0] log_out,
    input wire log_valid,
    input wire [4:0] num_mfcc_coeffs,
    output reg [MFCC_FEATURES*ACTIV_BITS-1:0] dct_out,
    output reg dct_valid
);

// Constants
localparam MAX_COEFFS = 32;
localparam COEFF_BITS = 16;

// Intermediate variables
reg [31:0] dct_input [0:MAX_COEFFS-1];
reg [$clog2(MAX_COEFFS)-1:0] log_idx;
reg [4:0] coeff_idx;

// Loeffler DCT algorithm
function [31:0] loeffler_dct;
    input [31:0] x0, x1, x2, x3, x4, x5, x6, x7;
    reg [31:0] a0, a1, a2, a3, a4, a5, a6, a7;
    reg [31:0] b0, b1, b2, b3, b4, b5, b6, b7;
begin
    // Stage 1
    a0 = x0 + x7;
    a1 = x1 + x6;
    a2 = x2 + x5;
    a3 = x3 + x4;
    a4 = x3 - x4;
    a5 = x2 - x5;
    a6 = x1 - x6;
    a7 = x0 - x7;

    // Stage 2
    b0 = a0 + a3;
    b1 = a1 + a2;
    b2 = a1 - a2;
    b3 = a0 - a3;
    b4 = a4;
    b5 = a5;
    b6 = a6;
    b7 = a7;

    // Stage 3
    a0 = b0 + b1;
    a1 = b0 - b1;
    a2 = b2 + b3;
    a3 = b3 - b2;
    a4 = b4 + b5;
    a5 = b4 - b5;
    a6 = b6 + b7;
    a7 = b6 - b7;

    // Stage 4
    b0 = a0;
    b1 = a1;
    b2 = a2 >>> 1;
    b3 = a3 >>> 1;
    b4 = a4;
    b5 = (a5 * 181) >>> 8;
    b6 = (a6 * 97) >>> 8;
    b7 = (a7 * 22) >>> 8;

    // Output
    loeffler_dct = {b0, b1, b2, b3, b4, b5, b6, b7};
end
endfunction

// DCT computation pipeline
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dct_out <= 'b0;
        dct_valid <= 1'b0;
        log_idx <= 'h0;
        coeff_idx <= 5'h0;
    end else if (log_valid) begin
        dct_input[log_idx] <= log_out;
        log_idx <= log_idx + 1;

        if (log_idx == MAX_COEFFS[$clog2(MAX_COEFFS)-1:0] - 1) begin
            if (coeff_idx < num_mfcc_coeffs) begin
                for (i = 0; i < MFCC_FEATURES; i = i + 8) begin
                    dct_out[i*ACTIV_BITS +: ACTIV_BITS*8] <= loeffler_dct(
                        dct_input[i], dct_input[i+1], dct_input[i+2], dct_input[i+3],
                        dct_input[i+4], dct_input[i+5], dct_input[i+6], dct_input[i+7]
                    )[ACTIV_BITS*8-1:0];
                end
                dct_valid <= 1'b1;
                coeff_idx <= coeff_idx + 1;
            end else begin
                dct_valid <= 1'b0;
                coeff_idx <= 5'h0;
            end
            log_idx <= 'h0;
        end else begin
            dct_valid <= 1'b0;
        end
    end else begin
        dct_valid <= 1'b0;
    end
end

endmodule
`endif