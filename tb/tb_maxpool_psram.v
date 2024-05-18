`timescale 1ns / 1ps

module tb_maxpool_psram;

    // Parameters
    parameter INPUT_WIDTH = 40;
    parameter INPUT_HEIGHT = 1;
    parameter INPUT_CHANNELS = 8;
    parameter KERNEL_SIZE = 2;
    parameter STRIDE = 2;
    parameter ACTIV_BITS = 16;
    parameter ADDR_WIDTH = 24;

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg [ADDR_WIDTH-1:0] input_addr;
    reg [ADDR_WIDTH-1:0] output_addr;

    // Outputs
    wire done;
    wire psram_sck;
    wire psram_ce_n;
    wire [3:0] psram_douten;

    // Inouts
    wire [3:0] psram_d;

    // PSRAM memory model
    reg [31:0] psram_memory [0:2**ADDR_WIDTH-1];
    assign psram_d = psram_douten ? 4'bz : psram_memory[uut.addr][3:0];

    // Instantiate the Unit Under Test (UUT)
    maxpool_psram #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .INPUT_HEIGHT(INPUT_HEIGHT),
        .INPUT_CHANNELS(INPUT_CHANNELS),
        .KERNEL_SIZE(KERNEL_SIZE),
        .STRIDE(STRIDE),
        .ACTIV_BITS(ACTIV_BITS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_addr(input_addr),
        .output_addr(output_addr),
        .done(done),
        .psram_sck(psram_sck),
        .psram_ce_n(psram_ce_n),
        .psram_d(psram_d),
        .psram_douten(psram_douten)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg [ACTIV_BITS-1:0] input_data [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:INPUT_CHANNELS-1];
    reg [ACTIV_BITS-1:0] expected_output [(INPUT_HEIGHT/STRIDE)-1:0][(INPUT_WIDTH/STRIDE)-1:0][0:INPUT_CHANNELS-1];
    integer i, j, k, m, n, addr_idx;
    reg [31:0] error_count;

    // Task to initialize input data in PSRAM memory
    task initialize_input_data;
        integer i, j, k;
        begin
            addr_idx = input_addr;
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                    for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                        psram_memory[addr_idx] = {16'b0, input_data[i][j][k]};
                        addr_idx = addr_idx + 1;
                    end
                end
            end
        end
    endtask

    // Task to read output data from PSRAM memory
    task read_output_data;
        output reg [ACTIV_BITS-1:0] data [(INPUT_HEIGHT/STRIDE)-1:0][(INPUT_WIDTH/STRIDE)-1:0][0:INPUT_CHANNELS-1];
        integer i, j, k;
        begin
            addr_idx = output_addr;
            for (i = 0; i < INPUT_HEIGHT/STRIDE; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH/STRIDE; j = j + 1) begin
                    for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                        data[i][j][k] = psram_memory[addr_idx][ACTIV_BITS-1:0];
                        addr_idx = addr_idx + 1;
                    end
                end
            end
        end
    endtask

    // Task to compute expected maxpool output
    task compute_expected_output;
        input reg [ACTIV_BITS-1:0] data [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:INPUT_CHANNELS-1];
        output reg [ACTIV_BITS-1:0] maxpool_out [(INPUT_HEIGHT/STRIDE)-1:0][(INPUT_WIDTH/STRIDE)-1:0][0:INPUT_CHANNELS-1];
        integer i, j, k, m, n;
        begin
            for (i = 0; i < INPUT_HEIGHT/STRIDE; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH/STRIDE; j = j + 1) begin
                    for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                        maxpool_out[i][j][k] = data[i*STRIDE][j*STRIDE][k];
                        for (m = 0; m < KERNEL_SIZE; m = m + 1) begin
                            for (n = 0; n < KERNEL_SIZE; n = n + 1) begin
                                if (i*STRIDE + m < INPUT_HEIGHT && j*STRIDE + n < INPUT_WIDTH) begin
                                    maxpool_out[i][j][k] = (data[i*STRIDE + m][j*STRIDE + n][k] > maxpool_out[i][j][k]) ? data[i*STRIDE + m][j*STRIDE + n][k] : maxpool_out[i][j][k];
                                end
                            end
                        end
                    end
                end
            end
        end
    endtask

    // Test case: Verify maxpool_psram functionality
    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        input_addr = 24'h000000;
        output_addr = 24'h000100;
        error_count = 0;

        // Initialize input data
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                    input_data[i][j][k] = (i * INPUT_WIDTH * INPUT_CHANNELS) + (j * INPUT_CHANNELS) + k;
                end
            end
        end

        // Load input data into PSRAM memory
        initialize_input_data();

        // Compute expected output
        compute_expected_output(input_data, expected_output);

        // Release reset
        #20;
        rst = 0;

        // Start the maxpool operation
        #20;
        start = 1;
        #10;
        start = 0;

        // Wait for the operation to complete
        wait(done);

        // Read output data from PSRAM memory
        reg [ACTIV_BITS-1:0] actual_output [(INPUT_HEIGHT/STRIDE)-1:0][(INPUT_WIDTH/STRIDE)-1:0][0:INPUT_CHANNELS-1];
        read_output_data(actual_output);

        // Compare expected and actual output
        for (i = 0; i < INPUT_HEIGHT/STRIDE; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH/STRIDE; j = j + 1) begin
                for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                    if (actual_output[i][j][k] !== expected_output[i][j][k]) begin
                        $display("ERROR: Mismatch at [%0d][%0d][%0d]: expected=%0d, got=%0d", i, j, k, expected_output[i][j][k], actual_output[i][j][k]);
                        error_count = error_count + 1;
                    end
                end
            end
        end

        if (error_count == 0) begin
            $display("All test cases passed!");
        end else begin
            $display("%0d test cases failed.", error_count);
        end

        $finish;
    end

endmodule
