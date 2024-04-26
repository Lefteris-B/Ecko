`timescale 1ns / 1ps

module mfcc_accelerator_tb;

// Parameters
localparam CLK_PERIOD = 10;  // Clock period (in nanoseconds)
localparam NUM_SAMPLES = 1024;  // Number of input audio samples

// Inputs
reg clk;
reg rst_n;
reg [15:0] audio_in;
reg audio_valid;
reg [7:0] frame_size;
reg [7:0] frame_overlap;
reg [7:0] num_mel_filters;
reg [7:0] num_mfcc_coeffs;
reg [7:0] num_freqs;
reg [15:0] target_freqs [0:255];
reg [15:0] goertzel_coefs [0:255];

// Outputs
wire [31:0] mfcc_out;
wire mfcc_valid;

// Precalculated test values
reg [15:0] test_audio_data [0:NUM_SAMPLES-1];
reg [31:0] expected_mfcc_out [0:NUM_SAMPLES-1];

// Instantiate the mfcc_accelerator module
mfcc_accelerator dut (
    .clk(clk),
    .rst_n(rst_n),
    .audio_in(audio_in),
    .audio_valid(audio_valid),
    .frame_size(frame_size),
    .frame_overlap(frame_overlap),
    .num_mel_filters(num_mel_filters),
    .num_mfcc_coeffs(num_mfcc_coeffs),
    .num_freqs(num_freqs),
    .target_freqs(target_freqs),
    .goertzel_coefs(goertzel_coefs),
    .mfcc_out(mfcc_out),
    .mfcc_valid(mfcc_valid)
);

// Clock generation
always begin
    clk = 1'b0;
    #(CLK_PERIOD/2);
    clk = 1'b1;
    #(CLK_PERIOD/2);
end

// Stimulus and verification
initial begin
    // Initialize inputs
    rst_n = 1'b0;
    audio_in = 16'h0000;
    audio_valid = 1'b0;
    frame_size = 8'd256;
    frame_overlap = 8'd128;
    num_mel_filters = 8'd40;
    num_mfcc_coeffs = 8'd13;
    num_freqs = 8'd4;
    target_freqs[0] = 16'h1F40;  // 2000 Hz
    target_freqs[1] = 16'h2B11;  // 3000 Hz
    target_freqs[2] = 16'h36B0;  // 4000 Hz
    target_freqs[3] = 16'h4270;  // 5000 Hz
    goertzel_coefs[0] = 16'h7FFF;  // Coefficient for 2000 Hz
    goertzel_coefs[1] = 16'h7D14;  // Coefficient for 3000 Hz
    goertzel_coefs[2] = 16'h7A7D;  // Coefficient for 4000 Hz
    goertzel_coefs[3] = 16'h7642;  // Coefficient for 5000 Hz

    // Load precalculated test audio data
    $readmemh("test_audio_data.txt", test_audio_data);

    // Load expected MFCC output values
    $readmemh("expected_mfcc_out.txt", expected_mfcc_out);

    // Reset the module
    #(CLK_PERIOD);
    rst_n = 1'b1;

    // Apply test stimulus
    for (int i = 0; i < NUM_SAMPLES; i = i + 1) begin
        audio_in = test_audio_data[i];
        audio_valid = 1'b1;
        #(CLK_PERIOD);
    end
    audio_valid = 1'b0;

    // Wait for the MFCC output to be valid
    wait(mfcc_valid);

    // Verify the MFCC output
    for (int i = 0; i < NUM_SAMPLES; i = i + 1) begin
        assert(mfcc_out == expected_mfcc_out[i])
            else $error("MFCC output mismatch at sample %0d! Expected: %h, Got: %h", i, expected_mfcc_out[i], mfcc_out);
        #(CLK_PERIOD);
    end

    // End the simulation
    #(CLK_PERIOD);
    $finish;
end

endmodule