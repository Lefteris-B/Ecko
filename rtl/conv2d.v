module conv2d #(
    parameter INPUT_WIDTH = 40, // MFCC features
    parameter INPUT_HEIGHT = 1, // Single feature height
    parameter INPUT_CHANNELS = 1, // Single channel input
    parameter KERNEL_SIZE = 3,
    parameter NUM_FILTERS = 8,
    parameter PADDING = 1,
    parameter ACTIV_BITS = 16
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH * INPUT_HEIGHT * INPUT_CHANNELS * ACTIV_BITS-1:0] data_in,
    input wire data_valid,
    output reg [INPUT_WIDTH * INPUT_HEIGHT * NUM_FILTERS * ACTIV_BITS-1:0] data_out,
    output reg data_out_valid,
    input wire [NUM_FILTERS * INPUT_CHANNELS * KERNEL_SIZE * KERNEL_SIZE * ACTIV_BITS-1:0] weights_in,
    input wire [NUM_FILTERS * ACTIV_BITS-1:0] biases_in,
    input wire load_weights,
    input wire load_biases
);

    // Declare weights and biases
    reg [ACTIV_BITS-1:0] weights [0:NUM_FILTERS-1][0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:NUM_FILTERS-1];

    // Declare internal signals
    reg [ACTIV_BITS-1:0] input_buffer [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:INPUT_CHANNELS-1];
    reg [2*ACTIV_BITS-1:0] conv_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:NUM_FILTERS-1];
    reg [ACTIV_BITS-1:0] relu_result [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:NUM_FILTERS-1];

    // Load weights and biases
    integer i_load, j_load, k_load, l_load;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset weights and biases
            for (i_load = 0; i_load < NUM_FILTERS; i_load = i_load + 1) begin
                for (j_load = 0; j_load < INPUT_CHANNELS; j_load = j_load + 1) begin
                    for (k_load = 0; k_load < KERNEL_SIZE; k_load = k_load + 1) begin
                        for (l_load = 0; l_load < KERNEL_SIZE; l_load = l_load + 1) begin
                            weights[i_load][j_load][k_load][l_load] <= 0;
                        end
                    end
                end
                biases[i_load] <= 0;
            end
        end else begin
            // Load weights when load_weights is asserted
            if (load_weights) begin
                for (i_load = 0; i_load < NUM_FILTERS; i_load = i_load + 1) begin
                    for (j_load = 0; j_load < INPUT_CHANNELS; j_load = j_load + 1) begin
                        for (k_load = 0; k_load < KERNEL_SIZE; k_load = k_load + 1) begin
                            for (l_load = 0; l_load < KERNEL_SIZE; l_load = l_load + 1) begin
                                weights[i_load][j_load][k_load][l_load] <= weights_in[(i_load*INPUT_CHANNELS*KERNEL_SIZE*KERNEL_SIZE + j_load*KERNEL_SIZE*KERNEL_SIZE + k_load*KERNEL_SIZE + l_load)*ACTIV_BITS +: ACTIV_BITS];
                            end
                        end
                    end
                end
            end
            // Load biases when load_biases is asserted
            if (load_biases) begin
                for (i_load = 0; i_load < NUM_FILTERS; i_load = i_load + 1) begin
                    biases[i_load] <= biases_in[i_load*ACTIV_BITS +: ACTIV_BITS];
                end
            end
        end
    end

    // Convolution operation
    integer m_conv, n_conv, p_conv, q_conv, i_conv, j_conv, k_conv;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal signals and output
            for (i_conv = 0; i_conv < INPUT_HEIGHT; i_conv = i_conv + 1) begin
                for (j_conv = 0; j_conv < INPUT_WIDTH; j_conv = j_conv + 1) begin
                    for (k_conv = 0; k_conv < INPUT_CHANNELS; k_conv = k_conv + 1) begin
                        input_buffer[i_conv][j_conv][k_conv] <= 0;
                    end
                    for (m_conv = 0; m_conv < NUM_FILTERS; m_conv = m_conv + 1) begin
                        conv_result[i_conv][j_conv][m_conv] <= 0;
                        relu_result[i_conv][j_conv][m_conv] <= 0;
                    end
                end
            end
            data_out <= 0;
            data_out_valid <= 0;
        end else if (data_valid) begin
            // Shift input data into buffer
            for (i_conv = 0; i_conv < INPUT_HEIGHT; i_conv = i_conv + 1) begin
                for (j_conv = 0; j_conv < INPUT_WIDTH; j_conv = j_conv + 1) begin
                    for (k_conv = 0; k_conv < INPUT_CHANNELS; k_conv = k_conv + 1) begin
                        if (j_conv < INPUT_WIDTH - 1) begin
                            input_buffer[i_conv][j_conv][k_conv] <= input_buffer[i_conv][j_conv+1][k_conv];
                        end else begin
                            input_buffer[i_conv][j_conv][k_conv] <= data_in[i_conv*INPUT_WIDTH*INPUT_CHANNELS*ACTIV_BITS + j_conv*INPUT_CHANNELS*ACTIV_BITS + k_conv*ACTIV_BITS +: ACTIV_BITS];
                        end
                    end
                end
            end

            // Perform convolution
            for (m_conv = 0; m_conv < INPUT_HEIGHT; m_conv = m_conv + 1) begin
                for (n_conv = 0; n_conv < INPUT_WIDTH; n_conv = n_conv + 1) begin
                    for (p_conv = 0; p_conv < NUM_FILTERS; p_conv = p_conv + 1) begin
                        conv_result[m_conv][n_conv][p_conv] = {{(2*ACTIV_BITS-ACTIV_BITS){1'b0}}, biases[p_conv]};
                        for (q_conv = 0; q_conv < INPUT_CHANNELS; q_conv = q_conv + 1) begin
                            for (i_conv = 0; i_conv < KERNEL_SIZE; i_conv = i_conv + 1) begin
                                for (j_conv = 0; j_conv < KERNEL_SIZE; j_conv = j_conv + 1) begin
                                    if (m_conv + i_conv - PADDING >= 0 && m_conv + i_conv - PADDING < INPUT_HEIGHT &&
                                        n_conv + j_conv - PADDING >= 0 && n_conv + j_conv - PADDING < INPUT_WIDTH) begin
                                        conv_result[m_conv][n_conv][p_conv] = conv_result[m_conv][n_conv][p_conv] + weights[p_conv][q_conv][i_conv][j_conv] * input_buffer[m_conv + i_conv - PADDING][n_conv + j_conv - PADDING][q_conv];
                                    end
                                end
                            end
                        end
                    end
                end
            end

            // Apply ReLU activation
            for (i_conv = 0; i_conv < INPUT_HEIGHT; i_conv = i_conv + 1) begin
                for (j_conv = 0; j_conv < INPUT_WIDTH; j_conv = j_conv + 1) begin
                    for (k_conv = 0; k_conv < NUM_FILTERS; k_conv = k_conv + 1) begin
                        relu_result[i_conv][j_conv][k_conv] = (conv_result[i_conv][j_conv][k_conv][2*ACTIV_BITS-1] == 0) ? conv_result[i_conv][j_conv][k_conv][ACTIV_BITS-1:0] : 0;
                    end
                end
            end

            // Assign output
            for (i_conv = 0; i_conv < INPUT_HEIGHT; i_conv = i_conv + 1) begin
                for (j_conv = 0; j_conv < INPUT_WIDTH; j_conv = j_conv + 1) begin
                    for (k_conv = 0; k_conv < NUM_FILTERS; k_conv = k_conv + 1) begin
                        data_out[i_conv*INPUT_WIDTH*NUM_FILTERS*ACTIV_BITS + j_conv*NUM_FILTERS*ACTIV_BITS + k_conv*ACTIV_BITS +: ACTIV_BITS] <= relu_result[i_conv][j_conv][k_conv];
                    end
                end
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

endmodule

