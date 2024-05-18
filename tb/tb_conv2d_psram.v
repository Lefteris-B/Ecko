`timescale 1ns / 1ps

module tb_conv2d_psram;

    // Parameters
    parameter INPUT_WIDTH = 40;
    parameter INPUT_HEIGHT = 1;
    parameter INPUT_CHANNELS = 1;
    parameter KERNEL_SIZE = 3;
    parameter NUM_FILTERS = 8;
    parameter PADDING = 1;
    parameter ACTIV_BITS = 16;
    parameter ADDR_WIDTH = 24;

    // Inputs
    reg clk;
    reg rst;
    reg [INPUT_WIDTH * INPUT_HEIGHT * INPUT_CHANNELS * ACTIV_BITS-1:0] data_in;
    reg data_valid;
    reg [ADDR_WIDTH-1:0] weight_base_addr;
    reg [ADDR_WIDTH-1:0] bias_base_addr;
    reg [ADDR_WIDTH-1:0] input_base_addr;
    reg [ADDR_WIDTH-1:0] output_base_addr;

    // Outputs
    wire [INPUT_WIDTH * INPUT_HEIGHT * NUM_FILTERS * ACTIV_BITS-1:0] data_out;
    wire data_out_valid;
    wire done;

    // PSRAM interface signals
    wire psram_sck;
    wire psram_ce_n;
    wire [3:0] psram_d;
    wire [3:0] psram_douten;

    // Instantiate the Unit Under Test (UUT)
    conv2d_psram #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .INPUT_HEIGHT(INPUT_HEIGHT),
        .INPUT_CHANNELS(INPUT_CHANNELS),
        .KERNEL_SIZE(KERNEL_SIZE),
        .NUM_FILTERS(NUM_FILTERS),
        .PADDING(PADDING),
        .ACTIV_BITS(ACTIV_BITS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .done(done),
        .psram_sck(psram_sck),
        .psram_ce_n(psram_ce_n),
        .psram_d(psram_d),
        .psram_douten(psram_douten),
        .weight_base_addr(weight_base_addr),
        .bias_base_addr(bias_base_addr),
        .input_base_addr(input_base_addr),
        .output_base_addr(output_base_addr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg [ACTIV_BITS-1:0] input_buffer [0:INPUT_WIDTH-1][0:INPUT_HEIGHT-1];
    reg [ACTIV_BITS-1:0] weights [0:NUM_FILTERS-1][0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:NUM_FILTERS-1];
    reg [ACTIV_BITS-1:0] conv_output [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:NUM_FILTERS-1];
    integer i, j, k, l, m, n, p, q;

    // Initialize PSRAM memory
    reg [31:0] psram_memory [0:2**ADDR_WIDTH-1];

    initial begin
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
            psram_memory[i] = 32'hA5A5A5A5;
        end
    end

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        data_in = 0;
        data_valid = 0;
        weight_base_addr = 0;
        bias_base_addr = 0;
        input_base_addr = 0;
        output_base_addr = 0;

        // Release reset
        #20;
        rst = 0;

        // Generate input data and weights
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            for (j = 0; j < INPUT_HEIGHT; j = j + 1) begin
                input_buffer[i][j] = i * INPUT_WIDTH + j;
            end
        end

        for (i = 0; i < NUM_FILTERS; i = i + 1) begin
            for (j = 0; j < INPUT_CHANNELS; j = j + 1) begin
                for (k = 0; k < KERNEL_SIZE; k = k + 1) begin
                    for (l = 0; l < KERNEL_SIZE; l = l + 1) begin
                        weights[i][j][k][l] = 1;
                    end
                end
            end
            biases[i] = i;
        end

        // Initialize PSRAM with weights and biases
        for (i = 0; i < NUM_FILTERS; i = i + 1) begin
            for (j = 0; j < INPUT_CHANNELS; j = j + 1) begin
                for (k = 0; k < KERNEL_SIZE; k = k + 1) begin
                    for (l = 0; l < KERNEL_SIZE; l = l + 1) begin
                        psram_memory[weight_base_addr + (i * INPUT_CHANNELS * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE * KERNEL_SIZE + k * KERNEL_SIZE + l) * 2] = weights[i][j][k][l];
                    end
                end
            end
            psram_memory[bias_base_addr + i * 2] = biases[i];
        end

        // Apply input data
        data_in = 0;
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
            for (j = 0; j < INPUT_HEIGHT; j = j + 1) begin
                data_in = data_in | (input_buffer[i][j] << (i * INPUT_HEIGHT + j) * ACTIV_BITS);
            end
        end
        data_valid = 1;
        #10;
        data_valid = 0;

        // Wait for the convolution operation to complete
        wait(done);

        // Verify convolution output
        for (m = 0; m < INPUT_HEIGHT; m = m + 1) begin
            for (n = 0; n < INPUT_WIDTH; n = n + 1) begin
                for (p = 0; p < NUM_FILTERS; p = p + 1) begin
                    conv_output[m][n][p] = biases[p];
                    for (q = 0; q < INPUT_CHANNELS; q = q + 1) begin
                        for (k = 0; k < KERNEL_SIZE; k = k + 1) begin
                            for (l = 0; l < KERNEL_SIZE; l = l + 1) begin
                                if ((m + k) < INPUT_HEIGHT && (n + l) < INPUT_WIDTH) begin
                                    conv_output[m][n][p] = conv_output[m][n][p] + weights[p][q][k][l] * input_buffer[n+l][m+k];
                                end
                            end
                        end
                    end
                    // Apply ReLU activation
                    conv_output[m][n][p] = (conv_output[m][n][p][ACTIV_BITS-1] == 0) ? conv_output[m][n][p] : 0;
                end
            end
        end

        // Verify the result from data_out
        for (m = 0; m < INPUT_HEIGHT; m = m + 1) begin
            for (n = 0; n < INPUT_WIDTH; n = n + 1) begin
                for (p = 0; p < NUM_FILTERS; p = p + 1) begin
                    assert(data_out[(m * INPUT_WIDTH * NUM_FILTERS + n * NUM_FILTERS + p) * ACTIV_BITS +: ACTIV_BITS] == conv_output[m][n][p])
                        else $fatal("ERROR: Convolution Output mismatch at position (%0d, %0d, %0d). Expected: %0d, Got: %0d", m, n, p, conv_output[m][n][p], data_out[(m * INPUT_WIDTH * NUM_FILTERS + n * NUM_FILTERS + p) * ACTIV_BITS +: ACTIV_BITS]);
                end
            end
        end

        $display("All test cases passed!");
        $finish;
    end

    // PSRAM memory model
    always @(posedge clk) begin
        if (psram_start && !psram_ce_n) begin
            if (psram_rd_wr == 0) begin
                // Write operation
                psram_memory[addr] <= psram_data;
            end else begin
                // Read operation
                psram_d <= psram_memory[addr][3:0];
            end
        end
    end

endmodule
