`ifndef FULLY_CONNECTED_V
`define FULLY_CONNECTED_V


module fully_connected #(
    parameter INPUT_SIZE = 640,
    parameter OUTPUT_SIZE = 64,
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
    reg [ACTIV_BITS-1:0] weights [0:OUTPUT_SIZE-1][0:INPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:OUTPUT_SIZE-1];

    // Declare internal signals
    reg [2*ACTIV_BITS-1:0] acc_result [0:OUTPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] relu_result [0:OUTPUT_SIZE-1];

    // Load weights and biases
    integer i, j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset weights and biases
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                    weights[i][j] = 0;
                end
                biases[i] <= 0;
            end
        end else begin
            // Load weights when load_weights is asserted
            if (load_weights) begin
                for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                    for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                        weights[i][j] = weights_in[(i*INPUT_SIZE + j)*ACTIV_BITS +: ACTIV_BITS];
                    end
                end
            end
            // Load biases when load_biases is asserted
            if (load_biases) begin
                for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                    biases[i] <= biases_in[i*ACTIV_BITS +: ACTIV_BITS];
                end
            end
        end
    end

    // Fully connected layer operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal signals and output
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                acc_result[i] <= 0;
                relu_result[i] <= 0;
            end
            data_out <= 0;
            data_out_valid <= 0;
        end else if (data_valid) begin
            // Perform matrix multiplication
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                acc_result[i] = biases[i];
                for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                    acc_result[i] = acc_result[i] + weights[i][j] * data_in[j*ACTIV_BITS +: ACTIV_BITS];
                end
            end

            // Apply ReLU activation
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                relu_result[i] <= (acc_result[i][2*ACTIV_BITS-1] == 0) ? acc_result[i][ACTIV_BITS-1:0] : 0;
            end

            // Assign output
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                data_out[i*ACTIV_BITS +: ACTIV_BITS] <= relu_result[i];
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

endmodule
`endif
