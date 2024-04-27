module fully_connected #(
    parameter INPUT_SIZE = 512,
    parameter OUTPUT_SIZE = 128,
    parameter ACTIVATION = "relu"
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE-1:0] data_in,
    input wire data_valid,
    output reg [OUTPUT_SIZE-1:0] data_out,
    output reg data_out_valid
);

// Declare weights and biases
reg [7:0] weights [0:OUTPUT_SIZE-1][0:INPUT_SIZE-1];
reg [7:0] biases [0:OUTPUT_SIZE-1];

// Declare internal signals
reg [15:0] mult_result [0:OUTPUT_SIZE-1];
reg [15:0] acc_result [0:OUTPUT_SIZE-1];
reg [15:0] relu_result [0:OUTPUT_SIZE-1];

// Fully connected layer operation
integer i, j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset internal signals and output
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            mult_result[i] <= 0;
            acc_result[i] <= 0;
            relu_result[i] <= 0;
        end
        data_out <= 0;
        data_out_valid <= 0;
    end else begin
        // Perform matrix multiplication
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            mult_result[i] <= 0;
            for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                mult_result[i] <= mult_result[i] + weights[i][j] * data_in[j];
            end
            acc_result[i] <= mult_result[i] + biases[i];
        end

        // Apply activation function (ReLU)
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            relu_result[i] <= (acc_result[i] > 0) ? acc_result[i] : 0;
        end

        // Assign output
        data_out <= relu_result;
        data_out_valid <= data_valid;
    end
end

endmodule