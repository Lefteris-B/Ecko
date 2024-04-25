// Pre-emphasis Filter Module
module pre_emphasis #(
    parameter DATA_WIDTH = 16,
    parameter COEFF      = 16'h7D8F  // 0.97 in Q15 format
)(
    input                      clk,
    input                      rst_n,
    input  [DATA_WIDTH-1:0]    audio_in,
    input                      audio_valid,
    output [DATA_WIDTH-1:0]    pre_emphasis_out
);

    // Registers
    reg [DATA_WIDTH-1:0] prev_sample;
    reg [DATA_WIDTH-1:0] pre_emphasis_reg;

    // Previous sample update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sample <= 0;
        end else if (audio_valid) begin
            prev_sample <= audio_in;
        end
    end

    // Pre-emphasis filter computation
    always @(posedge clk) begin
        if (audio_valid) begin
            pre_emphasis_reg <= audio_in - ((COEFF * prev_sample) >>> 15);
        end
    end

    // Output assignment
    assign pre_emphasis_out = pre_emphasis_reg;

endmodule