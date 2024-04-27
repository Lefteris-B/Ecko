`timescale 1ns / 1ps

module maxpool2d_tb;

    // Parameters
    localparam INPUT_WIDTH = 32;
    localparam INPUT_HEIGHT = 32;
    localparam INPUT_CHANNELS = 16;
    localparam POOL_SIZE = 2;
    localparam ACTIV_BITS = 8;

    // Inputs
    reg clk;
    reg rst_n;
    reg [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS-1:0] input_data;
    reg input_valid;

    // Outputs
    wire [(INPUT_WIDTH/POOL_SIZE)*(INPUT_HEIGHT/POOL_SIZE)*INPUT_CHANNELS*ACTIV_BITS-1:0] output_data;
    wire output_valid;

    // Instantiate the maxpool2d module
    maxpool2d #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .INPUT_HEIGHT(INPUT_HEIGHT),
        .INPUT_CHANNELS(INPUT_CHANNELS),
        .POOL_SIZE(POOL_SIZE),
        .ACTIV_BITS(ACTIV_BITS)
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

        // Test case 1: Single input feature map
        input_data = {
            8'd1, 8'd2, 8'd3, 8'd4,
            8'd5, 8'd6, 8'd7, 8'd8,
            8'd9, 8'd10, 8'd11, 8'd12,
            8'd13, 8'd14, 8'd15, 8'd16
        };
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data === {8'd6, 8'd8, 8'd14, 8'd16}) else $error("Output data mismatch for test case 1");

        // Test case 2: Multiple input channels
        input_data = {
            8'd1, 8'd2, 8'd3, 8'd4,
            8'd5, 8'd6, 8'd7, 8'd8,
            8'd9, 8'd10, 8'd11, 8'd12,
            8'd13, 8'd14, 8'd15, 8'd16,
            8'd17, 8'd18, 8'd19, 8'd20,
            8'd21, 8'd22, 8'd23, 8'd24,
            8'd25, 8'd26, 8'd27, 8'd28,
            8'd29, 8'd30, 8'd31, 8'd32
        };
        input_valid = 1;
        #10 input_valid = 0;

        // Wait for output valid
        wait(output_valid === 1);

        // Check the output data
        assert(output_data === {8'd22, 8'd24, 8'd30, 8'd32, 8'd6, 8'd8, 8'd14, 8'd16}) else $error("Output data mismatch for test case 2");

        // Add more test cases as needed

        #10 $finish;
    end

    // Timeout assertion
    initial begin
        #1000 $error("Timeout: Simulation did not finish within 1000 time units");
        $finish;
    end

endmodule