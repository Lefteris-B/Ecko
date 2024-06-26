`ifndef GOERTZEL_DFT_V
`define GOERTZEL_DFT_V

module goertzel_dft #(
    parameter NUM_FREQS = 256,
    parameter COEF_SIZE = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [15:0] framed_out,
    input wire framed_valid,
    input wire [COEF_SIZE-1:0] goertzel_coefs,
    input wire goertzel_coefs_start,
    output reg goertzel_coefs_valid,
    output reg goertzel_coefs_done,
    output reg [31:0] dft_out,
    output reg dft_valid
);

    // Goertzel algorithm variables
    reg [31:0] q_prev [0:NUM_FREQS-1];
    reg [31:0] q_curr [0:NUM_FREQS-1];
    reg [$clog2(NUM_FREQS)-1:0] freq_idx;

    // Shift register and LUT for storing Goertzel coefficients
    reg [COEF_SIZE-1:0] goertzel_coefs_reg [0:NUM_FREQS-1];
    reg [$clog2(NUM_FREQS)-1:0] goertzel_coefs_cnt;

    // Goertzel coefficients loading process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            goertzel_coefs_cnt <= 0;
            goertzel_coefs_valid <= 0;
            goertzel_coefs_done <= 0;
        end else if (goertzel_coefs_start) begin
            goertzel_coefs_reg[goertzel_coefs_cnt] <= goertzel_coefs;
            goertzel_coefs_valid <= 1;
            if (goertzel_coefs_cnt == NUM_FREQS[$clog2(NUM_FREQS)-1:0] - 1) begin
                goertzel_coefs_done <= 1;
                goertzel_coefs_cnt <= 0;
            end else begin
                goertzel_coefs_cnt <= goertzel_coefs_cnt + 1;
            end
        end else begin
            goertzel_coefs_valid <= 0;
            goertzel_coefs_done <= 0;
        end
    end

    // Goertzel algorithm implementation
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < NUM_FREQS; j = j + 1) begin
                q_prev[j] <= 32'h0;
                q_curr[j] <= 32'h0;
            end
            freq_idx <= 0;
            dft_out <= 32'h0;
            dft_valid <= 1'b0;
        end else if (framed_valid) begin
            for (j = 0; j < NUM_FREQS; j = j + 1) begin
                // Create temporary variables
                reg [31:0] q_curr_temp;
                reg [31:0] q_prev_temp;

                // Compute Goertzel algorithm using loaded coefficients from LUT
                q_curr_temp = ({{24{goertzel_coefs_reg[j][COEF_SIZE-1]}}, goertzel_coefs_reg[j]} * q_prev[j] >>> 15) - q_curr[j] + {{16{framed_out[15]}}, framed_out};
                q_prev_temp = q_curr[j];

                // Assign the updated values to the arrays
                q_curr[j] <= q_curr_temp;
                q_prev[j] <= q_prev_temp;
            end

            // Increment frequency index
            freq_idx <= freq_idx + 1;

            // Output DFT result when all frequencies are processed
            if (freq_idx == NUM_FREQS[$clog2(NUM_FREQS)-1:0] - 1) begin
                dft_out <= q_curr[freq_idx]*q_curr[freq_idx] + q_prev[freq_idx]*q_prev[freq_idx] - ({{24{goertzel_coefs_reg[freq_idx][COEF_SIZE-1]}}, goertzel_coefs_reg[freq_idx]} * q_curr[freq_idx] >>> 15);
                dft_valid <= 1'b1;
                freq_idx <= 0;
            end else begin
                dft_valid <= 1'b0;
            end
        end else begin
            dft_valid <= 1'b0;
        end
    end

endmodule

`endif
