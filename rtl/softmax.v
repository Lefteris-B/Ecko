`ifndef SOFTMAX_V
`define SOFTMAX_V

module softmax #(
    parameter INPUT_SIZE = 128,
    parameter OUTPUT_SIZE = 128,
    parameter ACTIV_BITS = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE*ACTIV_BITS-1:0] data_in,
    input wire data_valid,
    output reg [OUTPUT_SIZE*ACTIV_BITS-1:0] data_out,
    output reg data_out_valid
);

// Declare internal signals
reg [ACTIV_BITS-1:0] exp_values [0:INPUT_SIZE-1];
reg [2*ACTIV_BITS-1:0] sum_exp;
reg [ACTIV_BITS-1:0] softmax_values [0:OUTPUT_SIZE-1];

// Softmax activation function
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset internal signals and output
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            exp_values[i] = 0;
        end
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            softmax_values[i] = 0;
        end
        sum_exp = 0;
        data_out = 0;
        data_out_valid = 0;
    end else begin
        // Compute exponential values
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            exp_values[i] = data_in[i*ACTIV_BITS +: ACTIV_BITS];
        end

        // Compute sum of exponential values
        sum_exp = 0;
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            sum_exp = sum_exp + {{ACTIV_BITS{1'b0}}, exp_values[i]};
        end

        // Compute softmax values
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            reg [ACTIV_BITS-1:0] softmax_temp;
            softmax_temp = ({{ACTIV_BITS{1'b0}}, exp_values[i]} << ACTIV_BITS) / sum_exp;
            softmax_values[i] = softmax_temp;
        end

        // Assign output
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            data_out[i*ACTIV_BITS +: ACTIV_BITS] = softmax_values[i];
        end
        data_out_valid = data_valid;
    end
end

endmodule
`endif