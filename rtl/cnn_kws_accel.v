module cnn_kws_accel (
    input wire clk,
    input wire rst_n,
    input wire [40*1*1*16-1:0] data_in,
    input wire data_valid,
    output wire [40*1*8*16-1:0] conv1_out,
    output wire conv1_out_valid,
    output wire [40*1*8*16-1:0] conv2_out,
    output wire conv2_out_valid,
    output wire [64*16-1:0] fc1_out,
    output wire fc1_out_valid,
    output wire [64*16-1:0] fc2_out,
    output wire fc2_out_valid,

    // Base addresses for weights and biases
    input wire [23:0] conv1_weight_base_addr,
    input wire [23:0] conv1_bias_base_addr,
    input wire [23:0] conv2_weight_base_addr,
    input wire [23:0] conv2_bias_base_addr,
    input wire [23:0] fc1_weight_base_addr,
    input wire [23:0] fc1_bias_base_addr,
    input wire [23:0] fc2_weight_base_addr,
    input wire [23:0] fc2_bias_base_addr,

    // PSRAM interface signals
    output wire psram_sck,
    output wire psram_ce_n,
    inout wire [3:0] psram_d,
    output wire [3:0] psram_douten
);

    // Instantiate conv2d_psram for the first convolution layer
    conv2d_psram #(
        .INPUT_WIDTH(40),
        .INPUT_HEIGHT(1),
        .INPUT_CHANNELS(1),
        .KERNEL_SIZE(3),
        .NUM_FILTERS(8),
        .PADDING(1),
        .ACTIV_BITS(16)
    ) conv1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(conv1_out),
        .data_out_valid(conv1_out_valid),
        .psram_sck(psram_sck),
        .psram_ce_n(psram_ce_n),
        .psram_d(psram_d),
        .psram_douten(psram_douten),
        .weight_base_addr(conv1_weight_base_addr),
        .bias_base_addr(conv1_bias_base_addr)
    );

    // Instantiate conv2d_psram for the second convolution layer
    conv2d_psram #(
        .INPUT_WIDTH(40),
        .INPUT_HEIGHT(1),
        .INPUT_CHANNELS(8),
        .KERNEL_SIZE(3),
        .NUM_FILTERS(8),
        .PADDING(1),
        .ACTIV_BITS(16)
    ) conv2 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(conv1_out),
        .data_valid(conv1_out_valid),
        .data_out(conv2_out),
        .data_out_valid(conv2_out_valid),
        .psram_sck(psram_sck),
        .psram_ce_n(psram_ce_n),
        .psram_d(psram_d),
        .psram_douten(psram_douten),
        .weight_base_addr(conv2_weight_base_addr),
        .bias_base_addr(conv2_bias_base_addr)
    );

    // Instantiate fully_connected_psram for the first fully connected layer
    fully_connected_psram #(
        .INPUT_SIZE(320),
        .OUTPUT_SIZE(64),
        .ACTIV_BITS(16)
    ) fc1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(conv2_out),
        .data_valid(conv2_out_valid),
        .data_out(fc1_out),
        .data_out_valid(fc1_out_valid),
        .psram_sck(psram_sck),
        .psram_ce_n(psram_ce_n),
        .psram_d(psram_d),
        .psram_douten(psram_douten),
        .weight_base_addr(fc1_weight_base_addr),
        .bias_base_addr(fc1_bias_base_addr)
    );

    // Instantiate fully_connected_psram for the second fully connected layer
    fully_connected_psram #(
        .INPUT_SIZE(64),
        .OUTPUT_SIZE(64),
        .ACTIV_BITS(16)
    ) fc2 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(fc1_out),
        .data_valid(fc1_out_valid),
        .data_out(fc2_out),
        .data_out_valid(fc2_out_valid),
        .psram_sck(psram_sck),
        .psram_ce_n(psram_ce_n),
        .psram_d(psram_d),
        .psram_douten(psram_douten),
        .weight_base_addr(fc2_weight_base_addr),
        .bias_base_addr(fc2_bias_base_addr)
    );

endmodule

