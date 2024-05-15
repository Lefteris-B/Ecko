`ifdef USE_POWER_PINS
    .vccd1(vccd1),    // User area 1 1.8V power
    .vssd1(vssd1),    // User area 1 digital ground
`endif

module cnn_kws_accel (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [15:0] audio_sample, // Audio sample input
    input wire sample_valid, // New input to indicate the sample is accepted
    output wire done,
    // PSRAM signals
    output wire psram_sck,
    output wire psram_ce_n,
    inout wire [3:0] psram_d,
    output wire [3:0] psram_douten
);

    // Internal signals for PSRAM
    wire conv1_psram_sck, fc1_psram_sck, maxpool_psram_sck, softmax_psram_sck;
    wire conv1_psram_ce_n, fc1_psram_ce_n, maxpool_psram_ce_n, softmax_psram_ce_n;
    wire [3:0] conv1_psram_douten, fc1_psram_douten, maxpool_psram_douten, softmax_psram_douten;
    wire [3:0] conv1_psram_d, fc1_psram_d, maxpool_psram_d, softmax_psram_d;

    // PSRAM data output
    wire [3:0] psram_d_in;

    // State definitions
    typedef enum logic [2:0] {
        IDLE,
        MFCC,
        CONV1,
        FC1,
        MAXPOOL,
        SOFTMAX
    } state_t;

    state_t state, next_state;

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = MFCC;
            MFCC: if (mfcc_valid) next_state = CONV1;
            CONV1: if (conv1_done) next_state = FC1;
            FC1: if (fc1_done) next_state = MAXPOOL;
            MAXPOOL: if (maxpool_done) next_state = SOFTMAX;
            SOFTMAX: if (softmax_done) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Multiplexer for PSRAM control signals
    assign psram_sck = (state == CONV1) ? conv1_psram_sck :
                       (state == FC1) ? fc1_psram_sck :
                       (state == MAXPOOL) ? maxpool_psram_sck :
                       softmax_psram_sck;

    assign psram_ce_n = (state == CONV1) ? conv1_psram_ce_n :
                        (state == FC1) ? fc1_psram_ce_n :
                        (state == MAXPOOL) ? maxpool_psram_ce_n :
                        softmax_psram_ce_n;

    assign psram_douten = (state == CONV1) ? conv1_psram_douten :
                          (state == FC1) ? fc1_psram_douten :
                          (state == MAXPOOL) ? maxpool_psram_douten :
                          softmax_psram_douten;

    assign psram_d_in = (state == CONV1) ? conv1_psram_d :
                        (state == FC1) ? fc1_psram_d :
                        (state == MAXPOOL) ? maxpool_psram_d :
                        softmax_psram_d;

    // Tristate buffer for psram_d
    assign psram_d = psram_douten ? psram_d_in : 4'bz;

    // Instantiate the MFCC feature extractor and other modules with PSRAM
    wire [639:0] mfcc_feature; // Assuming MFCC output size is 640 bits (40 coefficients * 16 bits)
    wire mfcc_valid;

    wire [23:0] conv1_weight_base_addr = 24'h000000;
    wire [23:0] conv1_bias_base_addr = 24'h000100;
    wire [23:0] fc1_weight_base_addr = 24'h000200;
    wire [23:0] fc1_bias_base_addr = 24'h000300;
    wire [23:0] maxpool_input_addr = 24'h000400;
    wire [23:0] maxpool_output_addr = 24'h000500;
    wire [23:0] softmax_input_addr = 24'h000600;
    wire [23:0] softmax_output_addr = 24'h000700;

    wire conv1_done, fc1_done, maxpool_done, softmax_done;
    wire conv1_data_valid = (state == CONV1);
    wire fc1_data_valid = (state == FC1);
    wire maxpool_data_valid = (state == MAXPOOL);
    wire softmax_start = (state == SOFTMAX);

    wire [320*16-1:0] conv1_data_out;
    wire conv1_data_out_valid;
    wire [64*16-1:0] fc1_data_out;
    wire fc1_data_out_valid;
    wire [10*16-1:0] maxpool_data_out;
    wire maxpool_data_out_valid;
    wire [10*8-1:0] softmax_data_out;
    wire softmax_data_out_valid;

    mfcc_accel mfcc (
        .clk(clk),
        .rst(rst_n),
        .audio_sample(audio_sample),
        .mfcc_feature(mfcc_feature),
        .mfcc_valid(mfcc_valid),
        .sample_valid(sample_valid) // Connect sample_valid to mfcc_accel
    );

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
        .data_in(mfcc_feature), // MFCC feature as input
        .data_valid(conv1_data_valid),
        .data_out(conv1_data_out),
        .data_out_valid(conv1_data_out_valid),
        .psram_sck(conv1_psram_sck),
        .psram_ce_n(conv1_psram_ce_n),
        .psram_d(conv1_psram_d),
        .psram_douten(conv1_psram_douten),
        .weight_base_addr(conv1_weight_base_addr),
        .bias_base_addr(conv1_bias_base_addr),
        .done(conv1_done)
    );

    fully_connected_psram #(
        .INPUT_SIZE(320),
        .OUTPUT_SIZE(64),
        .ACTIV_BITS(16)
    ) fc1 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(conv1_data_out),
        .data_valid(conv1_data_out_valid),
        .data_out(fc1_data_out),
        .data_out_valid(fc1_data_out_valid),
        .psram_sck(fc1_psram_sck),
        .psram_ce_n(fc1_psram_ce_n),
        .psram_d(fc1_psram_d),
        .psram_douten(fc1_psram_douten),
        .weight_base_addr(fc1_weight_base_addr),
        .bias_base_addr(fc1_bias_base_addr),
        .done(fc1_done)
    );

    maxpool_psram #(
        .INPUT_WIDTH(40),
        .INPUT_HEIGHT(1),
        .INPUT_CHANNELS(8),
        .KERNEL_SIZE(2),
        .STRIDE(2),
        .ACTIV_BITS(16),
        .ADDR_WIDTH(24)
    ) maxpool (
        .clk(clk),
        .rst_n(rst_n),
        .start(maxpool_data_valid),
        .input_addr(maxpool_input_addr),
        .output_addr(maxpool_output_addr),
        .done(maxpool_done),
        .psram_sck(maxpool_psram_sck),
        .psram_ce_n(maxpool_psram_ce_n),
        .psram_d(maxpool_psram_d),
        .psram_douten(maxpool_psram_douten)
    );

    softmax_psram #(
        .INPUT_SIZE(10),
        .ACTIV_BITS(8),
        .ADDR_WIDTH(24)
    ) softmax (
        .clk(clk),
        .rst_n(rst_n),
        .start(softmax_start),
        .input_addr(softmax_input_addr),
        .output_addr(softmax_output_addr),
        .size(3'b010),
        .cmd(8'hEB),
        .rd_wr(1'b1),
        .qspi(1'b0),
        .qpi(1'b0),
        .short_cmd(1'b0),
        .done(softmax_done),
        .psram_sck(softmax_psram_sck),
        .psram_ce_n(softmax_psram_ce_n),
        .psram_d(softmax_psram_d),
        .psram_douten(softmax_psram_douten)
    );

    // Assign overall done signal
    assign done = (state == SOFTMAX) && softmax_done;

endmodule

