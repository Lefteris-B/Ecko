`ifndef PREEMPHASIS_FILTER_V
`define PREEMPHASIS_FILTER_V

module preemphasis_filter (
    input wire clk,
    input wire rst_n,
    input wire [15:0] audio_in,
    input wire audio_valid,
    output reg [15:0] preemph_out,
    output reg preemph_valid
);

// Configurable pre-emphasis coefficient (0.97 by default)
localparam PREEMPH_COEF = 16'h7D71; // 0.97 in Q15 format

// Internal registers
reg [15:0] audio_delay;

// Pre-emphasis filtering logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        audio_delay <= 16'h0000;
        preemph_out <= 16'h0000;
        preemph_valid <= 1'b0;
    end else if (audio_valid) begin
        audio_delay <= audio_in;
        preemph_out <= $signed(audio_in) - $signed(($signed(audio_delay) * $signed(PREEMPH_COEF)) >>> 15);
        preemph_valid <= 1'b1;
    end else begin
        preemph_valid <= 1'b0;
    end
end

endmodule
`endif
