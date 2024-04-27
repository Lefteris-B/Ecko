module fully_connected #(
    parameter INPUT_SIZE = 512,
    parameter OUTPUT_SIZE = 64,
    parameter WEIGHT_BITS = 8,
    parameter ACTIV_BITS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE*ACTIV_BITS-1:0] input_data,
    input wire input_valid,
    input wire [INPUT_SIZE*OUTPUT_SIZE*WEIGHT_BITS-1:0] weights,
    input wire [OUTPUT_SIZE*ACTIV_BITS-1:0] biases,
    output reg [OUTPUT_SIZE*ACTIV_BITS-1:0] output_data,
    output reg output_valid
);

    // Intermediate signals
    wire [OUTPUT_SIZE*ACTIV_BITS-1:0] mult_result;
    wire [OUTPUT_SIZE*ACTIV_BITS-1:0] add_result;
    wire [OUTPUT_SIZE*ACTIV_BITS-1:0] relu_result;

    // Matrix-vector multiplication
    genvar i, j;
    generate
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            wire [ACTIV_BITS-1:0] mult_sum;
            assign mult_sum = 0;
            for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                wire [ACTIV_BITS-1:0] mult_product;
                assign mult_product = $signed(input_data[j*ACTIV_BITS +: ACTIV_BITS]) * $signed(weights[(i*INPUT_SIZE+j)*WEIGHT_BITS +: WEIGHT_BITS]);
                assign mult_sum = mult_sum + mult_product;
            end
            assign mult_result[i*ACTIV_BITS +: ACTIV_BITS] = mult_sum;
        end
    endgenerate

    // Bias addition
    generate
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            assign add_result[i*ACTIV_BITS +: ACTIV_BITS] = $signed(mult_result[i*ACTIV_BITS +: ACTIV_BITS]) + $signed(biases[i*ACTIV_BITS +: ACTIV_BITS]);
        end
    endgenerate

    // ReLU activation
    generate
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            assign relu_result[i*ACTIV_BITS +: ACTIV_BITS] = (add_result[i*ACTIV_BITS +: ACTIV_BITS] > 0) ? add_result[i*ACTIV_BITS +: ACTIV_BITS] : 0;
        end
    endgenerate

    // Output assignment and valid signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_data <= 0;
            output_valid <= 0;
        end else begin
            output_data <= relu_result;
            output_valid <= input_valid;
        end
    end

endmodule