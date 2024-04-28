module conv2d #(
    parameter INPUT_WIDTH = 32,
    parameter INPUT_HEIGHT = 1,
    parameter INPUT_CHANNELS = 1,
    parameter KERNEL_WIDTH = 3,
    parameter KERNEL_HEIGHT = 3,
    parameter NUM_FILTERS = 32,
    parameter STRIDE = 1,
    parameter PADDING = 1,
    parameter ACTIVATION = "relu"
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS-1:0] data_in,
    input wire data_valid,
    output reg [INPUT_WIDTH*INPUT_HEIGHT*NUM_FILTERS-1:0] data_out,
    output reg data_out_valid
);

// Declare weights and biases
reg [7:0] weights [0:NUM_FILTERS-1][0:INPUT_CHANNELS-1][0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1];
reg [7:0] biases [0:NUM_FILTERS-1];

// Declare internal signals
reg [INPUT_WIDTH-1:0] input_buffer [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];
reg [INPUT_WIDTH-1:0] conv_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];
reg [INPUT_WIDTH-1:0] relu_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];

// Convolution operation
integer i, j, k, l, m;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset internal signals and output
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                input_buffer[i][j] <= 0;
                conv_result[i][j] <= 0;
                relu_result[i][j] <= 0;
            end
        end
        data_out <= 0;
        data_out_valid <= 0;
    end else begin
        // Shift input data into buffer
        if (data_valid) begin
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH - 1; j = j + 1) begin
                    input_buffer[i][j] <= input_buffer[i][j + 1];
                end
                input_buffer[i][INPUT_WIDTH - 1] <= data_in[i*INPUT_WIDTH +: INPUT_WIDTH];
            end
        end

        // Perform convolution
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                conv_result[i][j] = 0;
                for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                    for (l = 0; l < INPUT_CHANNELS; l = l + 1) begin
                        for (m = 0; m < KERNEL_HEIGHT; m = m + 1) begin
                            if (i + m - PADDING >= 0 && i + m - PADDING < INPUT_HEIGHT) begin
                                conv_result[i][j] = conv_result[i][j] + weights[k][l][m][j] * input_buffer[i + m - PADDING][j];
                            end
                        end
                    end
                    conv_result[i][j] = conv_result[i][j] + biases[k];
                end
            end
        end

        // Apply ReLU activation
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                relu_result[i][j] <= (conv_result[i][j] > 0) ? conv_result[i][j] : 0;
            end
        end

        // Assign output
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                data_out[i*INPUT_WIDTH*NUM_FILTERS + j*NUM_FILTERS +: NUM_FILTERS] <= relu_result[i][j];
            end
        end
        data_out_valid <= 1;
    end
end

endmodule
