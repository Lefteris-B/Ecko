`timescale 1ns / 1ps

module fully_connected_tb;

    // Parameters
    localparam INPUT_SIZE = 4;
    localparam OUTPUT_SIZE = 2;
    localparam WEIGHT_BITS = 8;
    localparam ACTIV_BITS = 8;

    // Inputs
    reg clk;
    reg rst_n;
    reg [INPUT_SIZE*ACTIV_BITS-1:0] input_data;
    reg input_valid;
    reg [INPUT_SIZE*OUTPUT_SIZE*WEIGHT_BITS-1:0] weights;
    reg [OUTPUT_SIZE*ACTIV_BITS-1:0] biases;

    // Outputs
    wire [OUTPUT_SIZE*ACTIV_BITS-1:0] output_data;
    wire output_valid;

    // Instantiate the fully_connected module
    fully_connected #(
        .INPUT_SIZE(INPUT_SIZE),
        .OUTPUT_SIZE(OUTPUT_SIZE),
        .WEIGHT_BITS(WEIGHT_BITS),
        .ACTIV_BITS(ACTIV_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .input_data(input_data),
        .input_valid(input_valid),
        .weights(weights),
        .biases(biases),
        .output_data(output_data),
        .output_valid(output_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus and verification
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        input_data = 0;
        input_valid = 0;
        weights = 0;
        biases = 0;

        // Reset assertion
        #10 rst_n = 1;
        #10 assert(output_valid === 0) else $error("Output valid should be 0 after reset");

        // Test case 1: Positive weights and biases
        weights = {8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8};
        biases = {8'd10, 8'd20};
        input_data = {8'd1, 8'd2, 8'd3, 8'd4};
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data === {8'd70, 8'd100}) else $error("Output data mismatch for test case 1");

        // Test case 2: Negative weights and biases
        weights = {-8'd1, -8'd2, -8'd3, -8'd4, -8'd5, -8'd6, -8'd7, -8'd8};
        biases = {-8'd10, -8'd20};
        input_data = {8'd1, 8'd2, 8'd3, 8'd4};
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data === {8'd0, 8'd0}) else $error("Output data mismatch for test case 2");

        // Test case 3: Mixed weights and biases
        weights = {8'd1, -8'd2, 8'd3, -8'd4, -8'd5, 8'd6, -8'd7, 8'd8};
        biases = {8'd10, -8'd20};
        input_data = {8'd1, 8'd2, 8'd3, 8'd4};
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data === {8'd10, 8'd0}) else $error("Output data mismatch for test case 3");

        // Add more test cases as needed

        #10 $finish;
    end

    // Timeout assertion
    initial begin
        #1000 $error("Timeout: Simulation did not finish within 1000 time units");
        $finish;
    end

endmodule