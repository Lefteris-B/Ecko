`timescale 1ns / 1ps

module tb_mfcc_accel;

    // Parameters
    localparam AUDIO_SAMPLE_COUNT = 256; // Number of audio samples for testing

    // Inputs
    reg clk;
    reg rst;
    reg [15:0] audio_sample;
    reg sample_valid;

    // Outputs
    wire [639:0] mfcc_feature;
    wire mfcc_valid;

    // Instantiate the Unit Under Test (UUT)
    mfcc_accel uut (
        .clk(clk),
        .rst(rst),
        .audio_sample(audio_sample),
        .sample_valid(sample_valid),
        .mfcc_feature(mfcc_feature),
        .mfcc_valid(mfcc_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg [15:0] audio_samples[AUDIO_SAMPLE_COUNT-1:0];
    reg [639:0] expected_mfcc_feature;
    reg [31:0] error_count;
    integer i;

    // Task to generate a set of audio samples
    task generate_audio_samples;
        integer i;
        begin
            for (i = 0; i < AUDIO_SAMPLE_COUNT; i = i + 1) begin
                audio_samples[i] = i;
            end
        end
    endtask

    // Task to calculate the expected MFCC feature
    task calc_expected_mfcc_feature;
        output [639:0] mfcc_feature;
        begin
            // For simplicity, let's assume a direct copy of input samples to the MFCC feature
            // In practice, this should involve the actual MFCC computation
            mfcc_feature = 0;
            for (i = 0; i < 40; i = i + 1) begin
                mfcc_feature[i*16 +: 16] = audio_samples[i];
            end
        end
    endtask

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        audio_sample = 0;
        sample_valid = 0;
        error_count = 0;

        // Generate audio samples
        generate_audio_samples();

        // Calculate expected MFCC feature
        calc_expected_mfcc_feature(expected_mfcc_feature);

        // Release reset
        #20;
        rst = 0;

        // Send audio samples to the UUT
        for (i = 0; i < AUDIO_SAMPLE_COUNT; i = i + 1) begin
            audio_sample = audio_samples[i];
            sample_valid = 1;
            #10;
            sample_valid = 0;
            #10;
        end

        // Wait for MFCC feature to be valid and check outputs
        wait(mfcc_valid);

        if (mfcc_feature !== expected_mfcc_feature) begin
            $display("ERROR: Expected MFCC feature=%h, Actual MFCC feature=%h", expected_mfcc_feature, mfcc_feature);
            error_count = error_count + 1;
        end else begin
            $display("MFCC feature matched expected value.");
        end

        if (error_count == 0) begin
            $display("All test cases passed!");
        end else begin
            $display("%d test cases failed.", error_count);
        end

        $finish;
    end

endmodule
