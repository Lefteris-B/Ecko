`ifndef CONV2D_V
`define CONV2D_V

module conv2d #(
    parameter INPUT_WIDTH = 32,
    parameter INPUT_HEIGHT = 1,
    parameter INPUT_CHANNELS = 1,
    parameter KERNEL_SIZE = 3,
    parameter NUM_FILTERS = 8,
    parameter PADDING = 1,
    parameter ACTIV_BITS = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS*ACTIV_BITS-1:0] data_in,
    input wire data_valid,
    output reg [INPUT_WIDTH*INPUT_HEIGHT*NUM_FILTERS*ACTIV_BITS-1:0] data_out,
    output reg data_out_valid,
    input wire [NUM_FILTERS*INPUT_CHANNELS*KERNEL_SIZE*KERNEL_SIZE*ACTIV_BITS-1:0] weights_in,
    input wire [NUM_FILTERS*ACTIV_BITS-1:0] biases_in,
    input wire load_weights,
    input wire load_biases
);

    // Declare weights and biases
    reg [ACTIV_BITS-1:0] weights [0:NUM_FILTERS-1][0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:NUM_FILTERS-1];

    // Declare internal signals
    reg [ACTIV_BITS-1:0] input_buffer [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];
    reg [2*ACTIV_BITS-1:0] conv_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:NUM_FILTERS-1];
    reg [ACTIV_BITS-1:0] relu_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:NUM_FILTERS-1];

 // Load weights and biases
    integer i, j, k, l;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset weights and biases
            for (i = 0; i < NUM_FILTERS; i = i + 1) begin
                for (j = 0; j < INPUT_CHANNELS; j = j + 1) begin
                    for (k = 0; k < KERNEL_SIZE; k = k + 1) begin
                        for (l = 0; l < KERNEL_SIZE; l = l + 1) begin
                            weights[i][j][k][l] <= 0;
                        end
                    end
                end
                biases[i] <= 0;
            end
        end else begin
            // Load weights when load_weights is asserted
            if (load_weights) begin
                for (i = 0; i < NUM_FILTERS; i = i + 1) begin
                    for (j = 0; j < INPUT_CHANNELS; j = j + 1) begin
                        for (k = 0; k < KERNEL_SIZE; k = k + 1) begin
                            for (l = 0; l < KERNEL_SIZE; l = l + 1) begin
                                weights[i][j][k][l] = weights_in[(i*INPUT_CHANNELS*KERNEL_SIZE*KERNEL_SIZE + j*KERNEL_SIZE*KERNEL_SIZE + k*KERNEL_SIZE + l)*ACTIV_BITS +: ACTIV_BITS];
                            end
                        end
                    end
                end
            end
            // Load biases when load_biases is asserted
            if (load_biases) begin
                for (i = 0; i < NUM_FILTERS; i = i + 1) begin
                    biases[i] <= biases_in[i*ACTIV_BITS +: ACTIV_BITS];
                end
            end
        end
    end
    // Convolution operation
    integer m, n, p, q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal signals and output
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                    input_buffer[i][j] <= 0;
                    for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                        conv_result[i][j][k] <= 0;
                        relu_result[i][j][k] <= 0;
                    end
                end
            end
            data_out <= 0;
            data_out_valid <= 0;
        end else if (data_valid) begin
            // Shift input data into buffer
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH - 1; j = j + 1) begin
                    input_buffer[i][j] <= input_buffer[i][j + 1];
                end
                input_buffer[i][INPUT_WIDTH - 1] <= data_in[i*INPUT_WIDTH*INPUT_CHANNELS*ACTIV_BITS +: ACTIV_BITS];
            end

            // Perform convolution
            for (m = 0; m < INPUT_HEIGHT; m = m + 1) begin
                for (n = 0; n < INPUT_WIDTH; n = n + 1) begin
                    for (p = 0; p < NUM_FILTERS; p = p + 1) begin
                        conv_result[m][n][p] = biases[p];
                        for (q = 0; q < INPUT_CHANNELS; q = q + 1) begin
                            for (i = 0; i < KERNEL_SIZE; i = i + 1) begin
                                for (j = 0; j < KERNEL_SIZE; j = j + 1) begin
                                    if (m + i - PADDING >= 0 && m + i - PADDING < INPUT_HEIGHT &&
                                        n + j - PADDING >= 0 && n + j - PADDING < INPUT_WIDTH) begin
                                        conv_result[m][n][p] = conv_result[m][n][p] + weights[p][q][i][j] * input_buffer[m + i - PADDING][n + j - PADDING];
                                    end
                                end
                            end
                        end
                    end
                end
            end

            // Apply ReLU activation
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                    for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                        relu_result[i][j][k] = (conv_result[i][j][k][2*ACTIV_BITS-1] == 0) ? conv_result[i][j][k][ACTIV_BITS-1:0] : 0;
                    end
                end
            end

            // Assign output
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                    for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                        data_out[i*INPUT_WIDTH*NUM_FILTERS*ACTIV_BITS + j*NUM_FILTERS*ACTIV_BITS + k*ACTIV_BITS +: ACTIV_BITS] <= relu_result[i][j][k];
                    end
                end
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

endmodule
`endif
