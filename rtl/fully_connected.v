`ifndef FULLY_CONNECTED_V
`define FULLY_CONNECTED_V

module fully_connected #(
    parameter INPUT_SIZE = 512,
    parameter OUTPUT_SIZE = 128,
    parameter ACTIV_BITS = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE*ACTIV_BITS-1:0] data_in,
    input wire data_valid,
    output reg [OUTPUT_SIZE*ACTIV_BITS-1:0] data_out,
    output reg data_out_valid,
    input wire [OUTPUT_SIZE*INPUT_SIZE*ACTIV_BITS-1:0] weights_in,
    input wire [OUTPUT_SIZE*ACTIV_BITS-1:0] biases_in,
    input wire load_weights,
    input wire load_biases
);

// Declare weights and biases
reg [ACTIV_BITS-1:0] weights [0:OUTPUT_SIZE*INPUT_SIZE-1];
reg [ACTIV_BITS-1:0] biases [0:OUTPUT_SIZE-1];

// Declare internal signals
reg [2*ACTIV_BITS-1:0] acc_result [0:OUTPUT_SIZE-1];
reg [ACTIV_BITS-1:0] relu_result [0:OUTPUT_SIZE-1];

// Load weights and biases
integer i, j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset weights and biases
        for (i = 0; i < OUTPUT_SIZE*INPUT_SIZE; i = i + 1) begin
            weights[i] = 0;
        end
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            biases[i] = 0;
        end
    end else begin
        // Load weights when load_weights is asserted
        if (load_weights) begin
            for (i = 0; i < OUTPUT_SIZE*INPUT_SIZE; i = i + 1) begin
                weights[i] = weights_in[i*ACTIV_BITS +: ACTIV_BITS];
            end
        end
        // Load biases when load_biases is asserted
        if (load_biases) begin
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                biases[i] = biases_in[i*ACTIV_BITS +: ACTIV_BITS];
            end
        end
    end
end

// Fully connected layer operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset internal signals and output
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            acc_result[i] = 0;
            relu_result[i] = 0;
        end
        data_out = 0;
        data_out_valid = 0;
    end else begin
        // Perform matrix multiplication
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            reg [2*ACTIV_BITS-1:0] acc_temp;
            acc_temp = 0;
            for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                acc_temp = acc_temp + weights[i*INPUT_SIZE+j] * data_in[j*ACTIV_BITS +: ACTIV_BITS];
            end
            acc_result[i] = acc_temp + {{ACTIV_BITS{1'b0}}, biases[i]};
        end

        // Apply activation function (ReLU)
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            relu_result[i] = (acc_result[i][2*ACTIV_BITS-1] == 0) ? acc_result[i][ACTIV_BITS-1:0] : 0;
        end

        // Assign output
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            data_out[i*ACTIV_BITS +: ACTIV_BITS] = relu_result[i];
        end
        data_out_valid = data_valid;
    end
end
endmodule
`endif