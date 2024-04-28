module goertzel_dft (
    input wire clk,
    input wire rst_n,
    input wire [15:0] framed_out,
    input wire framed_valid,
    input wire [7:0] num_freqs,
    input wire [15:0] target_freqs [0:255],
    input wire [15:0] goertzel_coefs [0:255],
    output reg [31:0] dft_out,
    output reg dft_valid
);

// Goertzel algorithm variables
reg [31:0] q_prev [0:255];
reg [31:0] q_curr [0:255];
reg [15:0] sample_delay [0:255];
reg [$clog2(256)-1:0] freq_idx;

// Goertzel algorithm implementation
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 256; i = i + 1) begin
            q_prev[i] = 32'h0;
            q_curr[i] = 32'h0;
            sample_delay[i] = 16'h0;
        end
        freq_idx <= 'h0;
        dft_out <= 32'h0;
        dft_valid <= 1'b0;
    end else if (framed_valid) begin
        for (i = 0; i < num_freqs; i = i + 1) begin
            // Update delay sample
            sample_delay[i] = framed_out;
            
            // Compute Goertzel algorithm
            q_curr[i] = (goertzel_coefs[i] * q_prev[i] >>> 15) - q_curr[i] + framed_out;
            q_prev[i] = q_curr[i];
        end
        
        // Increment frequency index
        freq_idx <= freq_idx + 1;
        
        // Output DFT result when all frequencies are processed
        if (freq_idx == num_freqs - 1) begin
            dft_out <= q_curr[freq_idx] * q_curr[freq_idx] + q_prev[freq_idx] * q_prev[freq_idx] - (goertzel_coefs[freq_idx] * q_curr[freq_idx] >>> 15);
            dft_valid <= 1'b1;
        end else begin
            dft_valid <= 1'b0;
        end
    end else begin
        dft_valid <= 1'b0;
    end
end

endmodule
