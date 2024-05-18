`timescale 1ns / 1ps

module tb_fully_connected_psram;

    // Parameters
    parameter INPUT_SIZE = 320;
    parameter OUTPUT_SIZE = 64;
    parameter ACTIV_BITS = 16;
    parameter ADDR_WIDTH = 24;

    // Inputs
    reg clk;
    reg rst;
    reg [INPUT_SIZE*ACTIV_BITS-1:0] data_in;
    reg data_valid;
    reg [ADDR_WIDTH-1:0] weight_base_addr;
    reg [ADDR_WIDTH-1:0] bias_base_addr;
    reg [ADDR_WIDTH-1:0] output_base_addr;

    // Outputs
    wire [OUTPUT_SIZE*ACTIV_BITS-1:0] data_out;
    wire data_out_valid;
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
    fully_connected_psram #(
        .INPUT_SIZE(INPUT_SIZE),
        .OUTPUT_SIZE(OUTPUT_SIZE),
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
        .output_base_addr(output_base_addr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg [ACTIV_BITS-1:0] input_data [0:INPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] weights [0:OUTPUT_SIZE-1][0:INPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:OUTPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] expected_output [0:OUTPUT_SIZE-1];
    reg [31:0] error_count;
    integer i, j, addr_idx;

    // Task to initialize weights and biases in PSRAM memory
    task initialize_weights_biases;
        integer i, j;
        begin
            addr_idx = weight_base_addr;
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                    psram_memory[addr_idx] = {16'b0, weights[i][j]};
                    addr_idx = addr_idx + 1;
                end
            end
            addr_idx = bias_base_addr;
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                psram_memory[addr_idx] = {16'b0, biases[i]};
                addr_idx = addr_idx + 1;
            end
        end
    endtask

    // Task to compute expected fully connected output
    task compute_expected_output;
        input reg [ACTIV_BITS-1:0] data_in [0:INPUT_SIZE-1];
        input reg [ACTIV_BITS-1:0] weights [0:OUTPUT_SIZE-1][0:INPUT_SIZE-1];
        input reg [ACTIV_BITS-1:0] biases [0:OUTPUT_SIZE-1];
        output reg [ACTIV_BITS-1:0] output_data [0:OUTPUT_SIZE-1];
        integer i, j;
        begin
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                output_data[i] = biases[i];
                for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                    output_data[i] = output_data[i] + (weights[i][j] * data_in[j]);
                end
                // Apply ReLU activation
                output_data[i] = (output_data[i][ACTIV_BITS-1] == 0) ? output_data[i] : 0;
            end
        end
    endtask

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        data_in = 0;
        data_valid = 0;
        weight_base_addr = 24'h000000;
        bias_base_addr = 24'h000100;
        output_base_addr = 24'h000200;
        error_count = 0;

        // Initialize input data, weights, and biases
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            input_data[i] = i;
        end
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            biases[i] = i;
            for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                weights[i][j] = i + j;
            end
        end

        // Load weights and biases into PSRAM memory
        initialize_weights_biases();

        // Compute expected output
        compute_expected_output(input_data, weights, biases, expected_output);

        // Release reset
        #20;
        rst = 0;

        // Apply input data
        data_in = {input_data[0], input_data[1], input_data[2], input_data[3], input_data[4], input_data[5], input_data[6], input_data[7]};
        data_valid = 1;
        #10;
        data_valid = 0;

        // Wait for done signal
        wait(done);

        // Verify output data
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            if (data_out[i*ACTIV_BITS +: ACTIV_BITS] !== expected_output[i]) begin
                $display("ERROR: Output index=%d, Expected Output=%d, Actual Output=%d", i, expected_output[i], data_out[i*ACTIV_BITS +: ACTIV_BITS]);
                error_count = error_count + 1;
            end
        end

        if (error_count == 0) begin
            $display("All test cases passed!");
        end else begin
            $display("%d test cases failed.", error_count);
        end

        $finish;
    end

endmodule
