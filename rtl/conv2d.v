`ifndef CONV2D_V
`define CONV2D_V

module conv2d #(
    parameter INPUT_WIDTH = 32,
    parameter INPUT_HEIGHT = 1,
    parameter INPUT_CHANNELS = 1,
    parameter KERNEL_WIDTH = 3,
    parameter KERNEL_HEIGHT = 3,
    parameter NUM_FILTERS = 32,
    parameter PADDING = 1,
    parameter ACTIV_BITS = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS*ACTIV_BITS-1:0] data_in,
    input wire data_valid,
    output reg [INPUT_WIDTH*INPUT_HEIGHT*NUM_FILTERS*ACTIV_BITS-1:0] data_out,
    output reg data_out_valid,
    input wire [NUM_FILTERS*INPUT_CHANNELS*KERNEL_HEIGHT*KERNEL_WIDTH*ACTIV_BITS-1:0] weights_in,
    input wire [NUM_FILTERS*ACTIV_BITS-1:0] biases_in,
    input wire load_weights,
    input wire load_biases
);

// Declare weights and biases
reg [ACTIV_BITS-1:0] weights [0:NUM_FILTERS-1][0:INPUT_CHANNELS-1][0:KERNEL_HEIGHT-1][0:KERNEL_WIDTH-1];
reg [ACTIV_BITS-1:0] biases [0:NUM_FILTERS-1];

// Declare internal signals
reg [ACTIV_BITS-1:0] input_buffer [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];
reg [2*ACTIV_BITS-1:0] conv_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];
reg [ACTIV_BITS-1:0] relu_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];

// Load weights and biases
integer i, j, k, l;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset weights and biases
        for (i = 0; i < NUM_FILTERS; i = i + 1) begin
            for (j = 0; j < INPUT_CHANNELS; j = j + 1) begin
                for (k = 0; k < KERNEL_HEIGHT; k = k + 1) begin
                    for (l = 0; l < KERNEL_WIDTH; l = l + 1) begin
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
                    for (k = 0; k < KERNEL_HEIGHT; k = k + 1) begin
                        for (l = 0; l < KERNEL_WIDTH; l = l + 1) begin
                            weights[i][j][k][l] <= weights_in[(i*INPUT_CHANNELS*KERNEL_HEIGHT*KERNEL_WIDTH + j*KERNEL_HEIGHT*KERNEL_WIDTH + k*KERNEL_WIDTH + l)*ACTIV_BITS +: ACTIV_BITS];
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
integer m;
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
                input_buffer[i][INPUT_WIDTH - 1] <= data_in[i*INPUT_WIDTH*INPUT_CHANNELS*ACTIV_BITS +: ACTIV_BITS];
            end
        end

	// Perform convolution
	for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
	    for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
		conv_result[i][j] = 0;
		for (k = 0; k < NUM_FILTERS; k = k + 1) begin
		    for (l = 0; l < INPUT_CHANNELS; l = l + 1) begin
		        for (m = 0; m < KERNEL_WIDTH; m = m + 1) begin
		            if (j + m - PADDING >= 0 && j + m - PADDING < INPUT_WIDTH) begin
		                conv_result[i][j] = conv_result[i][j] + weights[k][l][i][m] * input_buffer[i][j + m - PADDING];
		            end
		        end
		    end
		    conv_result[i][j] = conv_result[i][j] + {{ACTIV_BITS{1'b0}}, biases[k]};
		end
	    end
	end

        // Apply ReLU activation
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                relu_result[i][j] <= (conv_result[i][j][2*ACTIV_BITS-1] == 0) ? conv_result[i][j][ACTIV_BITS-1:0] : 0;
            end
        end

        // Assign output
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                    data_out[i*INPUT_WIDTH*NUM_FILTERS*ACTIV_BITS + j*NUM_FILTERS*ACTIV_BITS + k*ACTIV_BITS +: ACTIV_BITS] <= relu_result[i][j];
                end
            end
        end
        data_out_valid <= 1;
    end
end

endmodule
`endif