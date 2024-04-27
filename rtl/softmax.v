module softmax #(
    parameter INPUT_SIZE = 128,
    parameter OUTPUT_SIZE = 2,
    parameter LUT_SIZE = 256,
    parameter LUT_WIDTH = 16
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE-1:0] data_in,
    input wire data_valid,
    output reg [OUTPUT_SIZE-1:0] data_out,
    output reg data_out_valid
);

// Declare internal signals
reg [LUT_WIDTH-1:0] exp_lut [0:LUT_SIZE-1];
reg [LUT_WIDTH-1:0] exp_values [0:INPUT_SIZE-1];
reg [31:0] sum_exp;
reg [LUT_WIDTH-1:0] softmax_values [0:INPUT_SIZE-1];

// Initialize the exponential LUT
integer i;
initial begin
    for (i = 0; i < LUT_SIZE; i = i + 1) begin
        exp_lut[i] = $rtoi($exp(i / 256.0) * (1 << LUT_WIDTH));
    end
end

// Softmax activation function
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset internal signals and output
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            exp_values[i] <= 0;
            softmax_values[i] <= 0;
        end
        sum_exp <= 0;
        data_out <= 0;
        data_out_valid <= 0;
    end else begin
        // Compute exponential values using LUT
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            exp_values[i] <= exp_lut[data_in[i]];
        end

        // Compute sum of exponential values
        sum_exp <= 0;
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            sum_exp <= sum_exp + exp_values[i];
        end

        // Compute softmax values
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            softmax_values[i] <= (exp_values[i] << 16) / sum_exp;
        end

        // Assign output
        data_out <= softmax_values[OUTPUT_SIZE-1:0];
        data_out_valid <= data_valid;
    end
end

endmodule