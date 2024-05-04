`ifndef LOGARITHM_COMP_V
`define LOGARITHM_COMP_V

module logarithm_comp (
    input wire clk,
    input wire rst_n,
    input wire [31:0] mel_fbank_out,
    input wire mel_fbank_valid,
    output reg [31:0] log_out,
    output reg log_valid
);

// Constants
localparam INT_BITS = 5;
localparam FRAC_BITS = 10;

// Logarithm calculation pipeline
reg [31:0] mel_fbank_reg;
reg [INT_BITS-1:0] characteristic;
reg [FRAC_BITS-1:0] mantissa;
reg [FRAC_BITS-1:0] log_mantissa;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mel_fbank_reg <= 32'h0;
        characteristic <= 'h0;
        mantissa <= 'h0;
        log_mantissa <= 'h0;
        log_out <= 32'h0;
        log_valid <= 1'b0;
    end else if (mel_fbank_valid) begin
        mel_fbank_reg <= mel_fbank_out;
        characteristic <= mel_fbank_out[30:26]; // Assuming 5-bit characteristic
        mantissa <= mel_fbank_out[25:16]; // Assuming 10-bit mantissa
        log_mantissa <= mantissa - 10'h200; // Mitchell's approximation
        log_out <= {characteristic, 6'h0} + {16'h0, log_mantissa}; // Combine characteristic and mantissa
        log_valid <= 1'b1;
    end else begin
        log_valid <= 1'b0;
    end
end

endmodule
`endif