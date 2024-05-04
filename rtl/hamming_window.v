module hamming_window #(
    parameter FRAME_SIZE = 256,
    parameter SAMPLE_WIDTH = 16,
    parameter COEFF_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [SAMPLE_WIDTH-1:0] audio_sample,
    input wire sample_valid,
    output reg [SAMPLE_WIDTH-1:0] windowed_sample,
    output reg sample_ready
);

localparam NUM_COEFFS = FRAME_SIZE;
localparam ALPHA = 16'h0800; // Alpha value for Hamming window (0.54 in fixed-point)

reg [$clog2(NUM_COEFFS)-1:0] coeff_idx;
wire [COEFF_WIDTH-1:0] cosine_approx;
wire [SAMPLE_WIDTH+COEFF_WIDTH-1:0] mult_result;

// Piecewise linear approximation of cosine function for Hamming window
function [COEFF_WIDTH-1:0] cosine_approx_func;
    input [$clog2(NUM_COEFFS)-1:0] idx;
    reg [COEFF_WIDTH-1:0] approx;
    begin
        if (idx < (NUM_COEFFS / 4)) begin
            approx = COEFF_WIDTH'h7FFF - (idx << 1);
        end else if (idx < (NUM_COEFFS / 2)) begin
            approx = COEFF_WIDTH'h0000 + (idx << 1);
        end else if (idx < (3 * NUM_COEFFS / 4)) begin
            approx = COEFF_WIDTH'h0000 - (idx << 1);
        end else begin
            approx = COEFF_WIDTH'h8001 + (idx << 1);
        end
        cosine_approx_func = approx;
    end
endfunction

assign cosine_approx = cosine_approx_func(coeff_idx);

// Multiply audio sample with approximated Hamming window coefficient
assign mult_result = audio_sample * (ALPHA - ((ALPHA * cosine_approx) >>> COEFF_WIDTH));

always @(posedge clk) begin
    if (rst) begin
        coeff_idx <= 0;
        sample_ready <= 0;
    end else begin
        if (sample_valid) begin
            windowed_sample <= mult_result[SAMPLE_WIDTH+COEFF_WIDTH-1:COEFF_WIDTH];
            coeff_idx <= (coeff_idx == NUM_COEFFS-1) ? 0 : coeff_idx + 1;
            sample_ready <= 1;
        end else begin
            sample_ready <= 0;
        end
    end
end

endmodule