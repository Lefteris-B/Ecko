`ifndef FULLY_CONNECTED_V
`define FULLY_CONNECTED_V

module fully_connected #(
    parameter INPUT_SIZE = 160,
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
    integer i_load, j_load;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset weights and biases
            for (i_load = 0; i_load < OUTPUT_SIZE; i_load = i_load + 1) begin
                for (j_load = 0; j_load < INPUT_SIZE; j_load = j_load + 1) begin
                    weights[i_load][j_load] <= 0;
                end
                biases[i_load] <= 0;
            end
        end else begin
            // Load weights when load_weights is asserted
            if (load_weights) begin
                for (i_load = 0; i_load < OUTPUT_SIZE; i_load = i_load + 1) begin
                    for (j_load = 0; j_load < INPUT_SIZE; j_load = j_load + 1) begin
                        weights[i_load][j_load] <= weights_in[(i_load*INPUT_SIZE + j_load)*ACTIV_BITS +: ACTIV_BITS];
                    end
                end
            end
            // Load biases when load_biases is asserted
            if (load_biases) begin
                for (i_load = 0; i_load < OUTPUT_SIZE; i_load = i_load + 1) begin
                    biases[i_load] <= biases_in[i_load*ACTIV_BITS +: ACTIV_BITS];
                end
            end
        end
    end

    // Fully connected layer operation
    integer i_fc, j_fc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal signals and output
            for (i_fc = 0; i_fc < OUTPUT_SIZE; i_fc = i_fc + 1) begin
                acc_result[i_fc] <= 0;
                relu_result[i_fc] <= 0;
            end
            data_out <= 0;
            data_out_valid <= 0;
        end else if (data_valid) begin
            // Perform matrix multiplication
            for (i_fc = 0; i_fc < OUTPUT_SIZE; i_fc = i_fc + 1) begin
                acc_result[i_fc] = {{(2*ACTIV_BITS-ACTIV_BITS){1'b0}}, biases[i_fc]};
                for (j_fc = 0; j_fc < INPUT_SIZE; j_fc = j_fc + 1) begin
                    acc_result[i_fc] = acc_result[i_fc] + weights[i_fc][j_fc] * data_in[j_fc*ACTIV_BITS +: ACTIV_BITS];
                end
            end

            // Apply ReLU activation
            for (i_fc = 0; i_fc < OUTPUT_SIZE; i_fc = i_fc + 1) begin
                relu_result[i_fc] <= (acc_result[i_fc][2*ACTIV_BITS-1] == 0) ? acc_result[i_fc][ACTIV_BITS-1:0] : 0;
            end

            // Assign output
            for (i_fc = 0; i_fc < OUTPUT_SIZE; i_fc = i_fc + 1) begin
                data_out[i_fc*ACTIV_BITS +: ACTIV_BITS] <= relu_result[i_fc];
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

endmodule
`endif
