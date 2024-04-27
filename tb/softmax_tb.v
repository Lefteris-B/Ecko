`timescale 1ns / 1ps

module softmax_tb;

    // Parameters
    localparam INPUT_SIZE = 4;
    localparam ACTIV_BITS = 8;
    localparam LUT_SIZE = 256;
    localparam LUT_ADDR_BITS = 8;

    // Inputs
    reg clk;
    reg rst_n;
    reg [INPUT_SIZE*ACTIV_BITS-1:0] input_data;
    reg input_valid;

    // Outputs
    wire [INPUT_SIZE*ACTIV_BITS-1:0] output_data;
    wire output_valid;

    // Instantiate the softmax module
    softmax #(
        .INPUT_SIZE(INPUT_SIZE),
        .ACTIV_BITS(ACTIV_BITS),
        .LUT_SIZE(LUT_SIZE),
        .LUT_ADDR_BITS(LUT_ADDR_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .input_data(input_data),
        .input_valid(input_valid),
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

        // Reset assertion
        #10 rst_n = 1;
        #10 assert(output_valid === 0) else $error("Output valid should be 0 after reset");

        // Test case 1: Uniform input values
        input_data = {8'd128, 8'd128, 8'd128, 8'd128};
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data === {8'd64, 8'd64, 8'd64, 8'd64}) else $error("Output data mismatch for test case 1");

        // Test case 2: Varying input values
        input_data = {8'd64, 8'd128, 8'd192, 8'd255};
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data[0*ACTIV_BITS +: ACTIV_BITS] < output_data[1*ACTIV_BITS +: ACTIV_BITS]) else $error("Output data order mismatch for test case 2");
        assert(output_data[1*ACTIV_BITS +: ACTIV_BITS] < output_data[2*ACTIV_BITS +: ACTIV_BITS]) else $error("Output data order mismatch for test case 2");
        assert(output_data[2*ACTIV_BITS +: ACTIV_BITS] < output_data[3*ACTIV_BITS +: ACTIV_BITS]) else $error("Output data order mismatch for test case 2");

        // Test case 3: Zero input values
        input_data = {8'd0, 8'd0, 8'd0, 8'd0};
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data === {8'd64, 8'd64, 8'd64, 8'd64}) else $error("Output data mismatch for test case 3");

        // Add more test cases as needed

        #10 $finish;
    end

    // Timeout assertion
    initial begin
        #1000 $error("Timeout: Simulation did not finish within 1000 time units");
        $finish;
    end

endmodule