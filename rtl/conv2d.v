module conv2d #(
    parameter INPUT_WIDTH = 32,
    parameter INPUT_HEIGHT = 32,
    parameter INPUT_CHANNELS = 3,
    parameter KERNEL_SIZE = 3,
    parameter NUM_FILTERS = 16,
    parameter WEIGHT_BITS = 8,
    parameter ACTIV_BITS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS-1:0] input_data,
    input wire input_valid,
    output reg [(INPUT_WIDTH-KERNEL_SIZE+1)*(INPUT_HEIGHT-KERNEL_SIZE+1)*NUM_FILTERS-1:0] output_data,
    output reg output_valid
);

    localparam OUTPUT_WIDTH = INPUT_WIDTH - KERNEL_SIZE + 1;
    localparam OUTPUT_HEIGHT = INPUT_HEIGHT - KERNEL_SIZE + 1;

    // Weights and biases
    reg signed [WEIGHT_BITS-1:0] weights [0:NUM_FILTERS-1][0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg signed [ACTIV_BITS-1:0] biases [0:NUM_FILTERS-1];

    // Input and output buffers
    reg [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS-1:0] input_buffer;
    wire signed [ACTIV_BITS-1:0] conv_result [0:OUTPUT_WIDTH-1][0:OUTPUT_HEIGHT-1][0:NUM_FILTERS-1];
    reg signed [ACTIV_BITS-1:0] output_buffer [0:OUTPUT_WIDTH-1][0:OUTPUT_HEIGHT-1][0:NUM_FILTERS-1];

    // Convolution operation
    genvar i, j, k, l;
    generate
        for (i = 0; i < OUTPUT_WIDTH; i = i + 1) begin
            for (j = 0; j < OUTPUT_HEIGHT; j = j + 1) begin
                for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                    wire signed [ACTIV_BITS-1:0] conv_sum;
                    assign conv_sum = biases[k] + conv_result[i][j][k];

                    // ReLU activation
                    assign output_buffer[i][j][k] = (conv_sum > 0) ? conv_sum : 0;

                    // Convolution
                    wire signed [ACTIV_BITS-1:0] conv_temp [0:INPUT_CHANNELS-1];
                    for (l = 0; l < INPUT_CHANNELS; l = l + 1) begin
                        assign conv_temp[l] = $signed(input_buffer[((i+l)*INPUT_HEIGHT+j)*INPUT_CHANNELS+l]) * $signed(weights[k][l]);
                    end
                    assign conv_result[i][j][k] = conv_temp[0] + conv_temp[1] + conv_temp[2];
                end
            end
        end
    endgenerate

    // Output flattening and valid signal generation
    integer m, n, p;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_data <= 0;
            output_valid <= 0;
        end else begin
            if (input_valid) begin
                input_buffer <= input_data;
                output_valid <= 0;
            end else begin
                output_valid <= 1;
                for (m = 0; m < OUTPUT_WIDTH; m = m + 1) begin
                    for (n = 0; n < OUTPUT_HEIGHT; n = n + 1) begin
                        for (p = 0; p < NUM_FILTERS; p = p + 1) begin
                            output_data[((m*OUTPUT_HEIGHT+n)*NUM_FILTERS+p)*ACTIV_BITS +: ACTIV_BITS] <= output_buffer[m][n][p];
                        end
                    end
                end
            end
        end
    end

endmodule