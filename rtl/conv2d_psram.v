module conv2d_psram #(
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
    
    // PSRAM controller
    inout EF_PSRAM_CTRL_V2 psram_ctrl,

    // Base addresses for weights and biases
    input wire [23:0] weight_base_addr,
    input wire [23:0] bias_base_addr
);

    // Internal signals for PSRAM controller
    reg [23:0] psram_addr;
    reg [31:0] psram_data_i;
    wire [31:0] psram_data_o;
    reg [2:0] psram_size;
    reg psram_start;
    wire psram_done;
    reg [7:0] psram_cmd;
    reg psram_rd_wr;
    reg psram_qspi;
    reg psram_qpi;
    reg psram_short_cmd;

    // Declare internal signals
    reg [ACTIV_BITS-1:0] weights [0:NUM_FILTERS-1][0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:NUM_FILTERS-1];

    // Load weights and biases from PSRAM
    task load_weights_biases;
        integer i, j, k, l;
        begin
            for (i = 0; i < NUM_FILTERS; i = i + 1) begin
                for (j = 0; j < INPUT_CHANNELS; j = j + 1) begin
                    for (k = 0; k < KERNEL_SIZE; k = k + 1) begin
                        for (l = 0; l < KERNEL_SIZE; l = l + 1) begin
                            // Read weight from PSRAM
                            psram_addr = weight_base_addr + (i * INPUT_CHANNELS * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE * KERNEL_SIZE + k * KERNEL_SIZE + l) * (ACTIV_BITS / 8);
                            psram_cmd = 8'h03; // read command
                            psram_start = 1;
                            wait(psram_done);
                            psram_start = 0;
                            weights[i][j][k][l] = psram_data_o[ACTIV_BITS-1:0];
                        end
                    end
                end
                // Read bias from PSRAM
                psram_addr = bias_base_addr + i * (ACTIV_BITS / 8);
                psram_cmd = 8'h03; // read command
                psram_start = 1;
                wait(psram_done);
                psram_start = 0;
                biases[i] = psram_data_o[ACTIV_BITS-1:0];
            end
        end
    endtask

    // Convolution operation
    integer m_conv, n_conv, p_conv, q_conv, i_conv, j_conv, k_conv;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal signals and output
            data_out <= 0;
            data_out_valid <= 0;
        end else if (data_valid) begin
            // Perform convolution
            for (m_conv = 0; m_conv < INPUT_HEIGHT; m_conv = m_conv + 1) begin
                for (n_conv = 0; n_conv < INPUT_WIDTH; n_conv = n_conv + 1) begin
                    for (p_conv = 0; p_conv < NUM_FILTERS; p_conv = p_conv + 1) begin
                        // Initialize convolution result with bias
                        reg [2*ACTIV_BITS-1:0] conv_result = {{(2*ACTIV_BITS-ACTIV_BITS){1'b0}}, biases[p_conv]};
                        for (q_conv = 0; q_conv < INPUT_CHANNELS; q_conv = q_conv + 1) begin
                            for (i_conv = 0; i_conv < KERNEL_SIZE; i_conv = i_conv + 1) begin
                                for (j_conv = 0; j_conv < KERNEL_SIZE; j_conv = j_conv + 1) begin
                                    if (m_conv + i_conv - PADDING >= 0 && m_conv + i_conv - PADDING < INPUT_HEIGHT &&
                                        n_conv + j_conv - PADDING >= 0 && n_conv + j_conv - PADDING < INPUT_WIDTH) begin
                                        conv_result = conv_result + weights[p_conv][q_conv][i_conv][j_conv] * data_in[(m_conv + i_conv - PADDING) * INPUT_WIDTH * INPUT_CHANNELS * ACTIV_BITS + (n_conv + j_conv - PADDING) * INPUT_CHANNELS * ACTIV_BITS + q_conv * ACTIV_BITS +: ACTIV_BITS];
                                    end
                                end
                            end
                        end
                        // Apply ReLU activation
                        reg [ACTIV_BITS-1:0] relu_result = (conv_result[2*ACTIV_BITS-1] == 0) ? conv_result[ACTIV_BITS-1:0] : 0;
                        // Assign output
                        data_out[m_conv * INPUT_WIDTH * NUM_FILTERS * ACTIV_BITS + n_conv * NUM_FILTERS * ACTIV_BITS + p_conv * ACTIV_BITS +: ACTIV_BITS] <= relu_result;
                    end
                end
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

    // Load weights and biases at startup
    initial begin
        load_weights_biases();
    end

endmodule
