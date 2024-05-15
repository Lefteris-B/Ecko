module cnn_kws_accel #(
    parameter NUM_KEYWORDS = 10,
    parameter MFCC_FEATURES = 40,
    parameter ACTIV_BITS = 16, // Each MFCC feature is 16 bits
    parameter FC1_INPUT_SIZE = (MFCC_FEATURES/2) * (CONV2_NUM_FILTERS),
    parameter FC1_OUTPUT_SIZE = 64,
    parameter FC2_INPUT_SIZE = 64,
    parameter FC2_OUTPUT_SIZE = NUM_KEYWORDS,
    parameter CONV1_KERNEL_SIZE = 3,
    parameter CONV1_NUM_FILTERS = 8,
    parameter CONV2_KERNEL_SIZE = 3,
    parameter CONV2_NUM_FILTERS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [15:0] audio_in,
    input wire audio_valid,
    output reg [NUM_KEYWORDS-1:0] kws_result,
    output reg kws_valid,

    // PSRAM interface
    output wire psram_sck,
    output wire psram_ce_n,
    inout wire [3:0] psram_d,
    output wire [3:0] psram_douten
);

    // MFCC module signals
    wire [639:0] mfcc_out; // 40 features * 16 bits
    wire mfcc_valid;

    // CNN-KWS layers
    wire [MFCC_FEATURES*CONV1_NUM_FILTERS*ACTIV_BITS-1:0] conv1_out;
    wire conv1_valid;
    wire [MFCC_FEATURES*CONV2_NUM_FILTERS*ACTIV_BITS-1:0] conv2_out;
    wire conv2_valid;
    wire [(MFCC_FEATURES/2)*CONV2_NUM_FILTERS*ACTIV_BITS-1:0] maxpool_out;
    wire maxpool_valid;
    wire [FC1_OUTPUT_SIZE*ACTIV_BITS-1:0] fc1_out;
    wire fc1_valid;
    wire [FC2_OUTPUT_SIZE*ACTIV_BITS-1:0] fc2_out;
    wire fc2_valid;
    wire [FC2_OUTPUT_SIZE*ACTIV_BITS-1:0] softmax_out;
    wire softmax_valid;

    // PSRAM signals
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

    // Instantiate PSRAM controller
    EF_PSRAM_CTRL_V2 psram_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .addr(psram_addr),
        .data_i(psram_data_i),
        .data_o(psram_data_o),
        .size(psram_size),
        .start(psram_start),
        .done(psram_done),
        .wait_states(8'b0),
        .cmd(psram_cmd),
        .rd_wr(psram_rd_wr),
        .qspi(psram_qspi),
        .qpi(psram_qpi),
        .short_cmd(psram_short_cmd),
        .sck(psram_sck),
        .ce_n(psram_ce_n),
        .din(psram_d),
        .dout(psram_d),
        .douten(psram_douten)
    );

    // MFCC module instantiation
    mfcc_accel mfcc (
        .clk(clk),
        .rst(rst_n),
        .audio_sample(audio_in),
        .sample_valid(audio_valid),
        .mfcc_feature(mfcc_out),
        .mfcc_valid(mfcc_valid)
    );

    // Convolutional layer 1
    conv2d_psram #(
        .INPUT_WIDTH(MFCC_FEATURES),
        .INPUT_HEIGHT(1),
        .INPUT_CHANNELS(1),
        .KERNEL_SIZE(CONV1_KERNEL_SIZE),
        .NUM_FILTERS(CONV1_NUM_FILTERS),
        .PADDING(1),
        .ACTIV_BITS(ACTIV_BITS)
    ) conv1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(mfcc_out),
        .data_valid(mfcc_valid),
        .data_out(conv1_out),
        .data_out_valid(conv1_valid),
        .psram_ctrl(psram_ctrl),
        .weight_base_addr(24'h000000), // Base address for conv1 weights
        .bias_base_addr(24'h000400)    // Base address for conv1 biases
    );

    // Convolutional layer 2
    conv2d_psram #(
        .INPUT_WIDTH(MFCC_FEATURES),
        .INPUT_HEIGHT(1),
        .INPUT_CHANNELS(CONV1_NUM_FILTERS),
        .KERNEL_SIZE(CONV2_KERNEL_SIZE),
        .NUM_FILTERS(CONV2_NUM_FILTERS),
        .PADDING(1),
        .ACTIV_BITS(ACTIV_BITS)
    ) conv2 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(conv1_out),
        .data_valid(conv1_valid),
        .data_out(conv2_out),
        .data_out_valid(conv2_valid),
        .psram_ctrl(psram_ctrl),
        .weight_base_addr(24'h000500), // Base address for conv2 weights
        .bias_base_addr(24'h000A00)    // Base address for conv2 biases
    );

    maxpool2d #(
        .INPUT_WIDTH(MFCC_FEATURES),
        .INPUT_HEIGHT(1),
        .INPUT_CHANNELS(CONV2_NUM_FILTERS),
        .KERNEL_SIZE(2),
        .STRIDE(2),
        .ACTIV_BITS(ACTIV_BITS)
    ) maxpool (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(conv2_out),
        .data_valid(conv2_valid),
        .data_out(maxpool_out),
        .data_out_valid(maxpool_valid)
    );

    fully_connected_psram #(
        .INPUT_SIZE(FC1_INPUT_SIZE),
        .OUTPUT_SIZE(FC1_OUTPUT_SIZE),
        .ACTIV_BITS(ACTIV_BITS)
    ) fc1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(maxpool_out),
        .data_valid(maxpool_valid),
        .data_out(fc1_out),
        .data_out_valid(fc1_valid),
        .psram_ctrl(psram_ctrl),
        .weight_base_addr(24'h000B00), // Base address for FC1 weights
        .bias_base_addr(24'h004C00)    // Base address for FC1 biases
    );

    fully_connected_psram #(
        .INPUT_SIZE(FC2_INPUT_SIZE),
        .OUTPUT_SIZE(FC2_OUTPUT_SIZE),
        .ACTIV_BITS(ACTIV_BITS)
    ) fc2 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(fc1_out),
        .data_valid(fc1_valid),
        .data_out(fc2_out),
        .data_out_valid(fc2_valid),
        .psram_ctrl(psram_ctrl),
        .weight_base_addr(24'h004D00), // Base address for FC2 weights
        .bias_base_addr(24'h005000)    // Base address for FC2 biases
    );

    // Softmax layer
    softmax #(
        .INPUT_SIZE(NUM_KEYWORDS),
        .ACTIV_BITS(ACTIV_BITS)
    ) softmax (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(fc2_out),
        .data_valid(fc2_valid),
        .data_out(softmax_out),
        .data_out_valid(softmax_valid)
    );

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            kws_result <= 'b0;
            kws_valid <= 1'b0;
        end else begin
            kws_result <= softmax_out[NUM_KEYWORDS-1:0];
            kws_valid <= softmax_valid;
        end
    end

endmodule
