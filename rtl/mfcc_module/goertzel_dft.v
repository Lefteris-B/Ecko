`ifndef GOERTZEL_DFT_V
`define GOERTZEL_DFT_V

module goertzel_dft (
    input wire clk,
    input wire rst_n,
    input wire [15:0] framed_out,
    input wire framed_valid,
    input wire [7:0] num_freqs,
    input wire [4095:0] target_freqs,
    input wire [4095:0] goertzel_coefs,
    output reg [31:0] dft_out,
    output reg dft_valid
);

// Goertzel algorithm variables
reg [31:0] q_prev [0:255];
reg [31:0] q_curr [0:255];
reg [15:0] sample_delay [0:255];
reg [7:0] freq_idx;

// Goertzel algorithm implementation
integer j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 256; j = j + 1) begin
            q_prev[j] = 32'h0;
            q_curr[j] = 32'h0;
            sample_delay[j] = 16'h0;
        end
        freq_idx <= 8'h0;
        dft_out <= 32'h0;
        dft_valid <= 1'b0;
    end else if (framed_valid) begin
        for (j = 0; j < 256; j = j + 1) begin // Change loop condition to a constant
            if (j < num_freqs) begin // Add an if statement to check against num_freqs
                // Update delay sample
                sample_delay[j] = framed_out;
                // Compute Goertzel algorithm
                q_curr[j] = (goertzel_coefs[j*16 +: 16] * q_prev[j] >>> 15) - q_curr[j] + framed_out;
                q_prev[j] = q_curr[j];
            end
        end
        // Increment frequency index
        freq_idx <= freq_idx + 1;
        // Output DFT result when all frequencies are processed
        if (freq_idx == num_freqs - 1) begin
            dft_out <= q_curr[freq_idx] * q_curr[freq_idx] + q_prev[freq_idx] * q_prev[freq_idx] - (goertzel_coefs[freq_idx*16 +: 16] * q_curr[freq_idx] >>> 15);
            dft_valid <= 1'b1;
        end else begin
            dft_valid <= 1'b0;
        end
    end else begin
        dft_valid <= 1'b0;
    end
end

endmodule
`endif