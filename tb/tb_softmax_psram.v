`timescale 1ns / 1ps

module tb_softmax_psram;
    // Parameters
    parameter INPUT_SIZE = 10;
    parameter ACTIV_BITS = 8;
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

    // Instantiate the Unit Under Test (UUT)
    softmax_psram #(
        .INPUT_SIZE(INPUT_SIZE),
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

    // PSRAM memory model
    reg [31:0] psram_memory [0:2**ADDR_WIDTH-1];
    assign psram_d = psram_douten ? 4'bz : psram_memory[uut.addr][3:0];

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    integer i;
    reg [ACTIV_BITS-1:0] input_data [0:INPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] expected_output [0:INPUT_SIZE-1];

    // Task to initialize input data in PSRAM memory
    task initialize_input_data;
        input [ACTIV_BITS-1:0] data [0:INPUT_SIZE-1];
        integer i;
        begin
            for (i = 0; i < INPUT_SIZE; i = i + 1) begin
                psram_memory[input_addr + i] = {24'b0, data[i]};
            end
        end
    endtask

    // Task to read output data from PSRAM memory
    task read_output_data;
        output [ACTIV_BITS-1:0] data [0:INPUT_SIZE-1];
        integer i;
        begin
            for (i = 0; i < INPUT_SIZE; i = i + 1) begin
                data[i] = psram_memory[output_addr + i][ACTIV_BITS-1:0];
            end
        end
    endtask

    // Task to compute expected softmax output
    task compute_expected_softmax;
        input [ACTIV_BITS-1:0] data [0:INPUT_SIZE-1];
        output [ACTIV_BITS-1:0] softmax [0:INPUT_SIZE-1];
        reg [2*ACTIV_BITS-1:0] exp_values [0:INPUT_SIZE-1];
        reg [2*ACTIV_BITS-1:0] sum_exp;
        integer i;
        begin
            // Initialize LUT for exponential function
            reg [2*ACTIV_BITS-1:0] exp_lut [0:255];
            // (initialization code for exp_lut)
            // Compute the sum of exponentials using LUT
            sum_exp = 0;
            for (i = 0; i < INPUT_SIZE; i = i + 1) begin
                exp_values[i] = exp_lut[data[i]];
                sum_exp = sum_exp + exp_values[i];
            end

            // Compute softmax values
            for (i = 0; i < INPUT_SIZE; i = i + 1) begin
                softmax[i] = (exp_values[i] << ACTIV_BITS) / sum_exp[2*ACTIV_BITS-1:ACTIV_BITS];
            end
        end
    endtask

    // Test case: Simple softmax computation
    initial begin
        // Initialize inputs
        rst = 1;
        start = 0;
        input_addr = 24'h000000;
        output_addr = 24'h000100;

        // Initialize input data
        input_data[0] = 8'd1;
        input_data[1] = 8'd2;
        input_data[2] = 8'd3;
        input_data[3] = 8'd4;
        input_data[4] = 8'd5;
        input_data[5] = 8'd6;
        input_data[6] = 8'd7;
        input_data[7] = 8'd8;
        input_data[8] = 8'd9;
        input_data[9] = 8'd10;

        // Load input data into PSRAM memory
        initialize_input_data(input_data);

        // Release reset
        #20;
        rst = 0;

        // Start the softmax operation
        #20;
        start = 1;
        #10;
        start = 0;

        // Wait for the operation to complete
        wait(done);

        // Read output data from PSRAM memory
        read_output_data(expected_output);

        // Compute expected output
        compute_expected_softmax(input_data, expected_output);

        // Compare expected and actual output
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            assert(output_data[i] == expected_output[i]) else $fatal("Mismatch at index %d: expected %d, got %d", i, expected_output[i], output_data[i]);
        end

        $display("All test cases passed!");
        $finish;
    end

endmodule
