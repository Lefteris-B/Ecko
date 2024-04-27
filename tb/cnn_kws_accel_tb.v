`timescale 1ns / 1ps

module cnn_kws_accel_tb;

    // Parameters
    localparam NUM_KEYWORDS = 10;
    localparam MFCC_FEATURES = 40;
    localparam MFCC_FRAMES = 100;
    localparam ACTIV_BITS = 8;

    // Inputs
    reg clk;
    reg rst_n;
    reg [MFCC_FEATURES*ACTIV_BITS-1:0] mfcc_data;
    reg mfcc_valid;

    // Outputs
    wire [NUM_KEYWORDS-1:0] kws_result;
    wire kws_valid;

    // Expected output
    reg [NUM_KEYWORDS-1:0] expected_result;

    // Instantiate the cnn_kws_accel module
    cnn_kws_accel #(
        .NUM_KEYWORDS(NUM_KEYWORDS),
        .MFCC_FEATURES(MFCC_FEATURES),
        .MFCC_FRAMES(MFCC_FRAMES),
        .ACTIV_BITS(ACTIV_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .mfcc_data(mfcc_data),
        .mfcc_valid(mfcc_valid),
        .kws_result(kws_result),
        .kws_valid(kws_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus and verification
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        mfcc_data = 0;
        mfcc_valid = 0;
        expected_result = 0;

        // Reset assertion
        #10 rst_n = 1;
        #10 assert(kws_valid === 0) else $error("KWS valid should be 0 after reset");

        // Test case 1: Keyword 1
        for (int i = 0; i < MFCC_FRAMES; i = i + 1) begin
            mfcc_data = $random;
            mfcc_valid = 1;
            #10;
        end
        mfcc_valid = 0;
        expected_result = 10'b0000000001;

        // Wait for KWS valid
        wait(kws_valid === 1);

        // Check the KWS result
        assert(kws_result === expected_result) else $error("KWS result mismatch for test case 1");

        // Test case 2: Keyword 5
        for (int i = 0; i < MFCC_FRAMES; i = i + 1) begin
            mfcc_data = $random;
            mfcc_valid = 1;
            #10;
        end
        mfcc_valid = 0;
        expected_result = 10'b0000010000;

        // Wait for KWS valid
        wait(kws_valid === 1);

        // Check the KWS result
        assert(kws_result === expected_result) else $error("KWS result mismatch for test case 2");

        // Test case 3: No keyword
        for (int i = 0; i < MFCC_FRAMES; i = i + 1) begin
            mfcc_data = $random;
            mfcc_valid = 1;
            #10;
        end
        mfcc_valid = 0;
        expected_result = 10'b0000000000;

        // Wait for KWS valid
        wait(kws_valid === 1);

        // Check the KWS result
        assert(kws_result === expected_result) else $error("KWS result mismatch for test case 3");

        // Add more test cases as needed

        #10 $finish;
    end

    // Timeout assertion
    initial begin
        #100000 $error("Timeout: Simulation did not finish within 100000 time units");
        $finish;
    end

endmodule