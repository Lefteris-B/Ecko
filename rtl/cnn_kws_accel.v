`include "preemphasis_filter.v"
`include "framing_windowing.v"
`include "goertzel_dft.v"
`include "mel_filterbank.v"
`include "logarithm_comp.v"
`include "dct_comp.v"
`include "mfcc_accelerator.v"
`include "conv2d.v"
`include "maxpool2d.v"
`include "fully_connected.v"
`include "softmax.v"

module cnn_kws_accel #(
    parameter NUM_KEYWORDS = 10,
    parameter MFCC_FEATURES = 40,
    parameter MFCC_FRAMES = 100,
    parameter ACTIV_BITS = 8,
    parameter NUM_MEL_FILTERS = 32
)(
    input wire clk,
    input wire rst_n,
    input wire [15:0] audio_in,
    input wire audio_valid,
    output wire [NUM_KEYWORDS-1:0] kws_result,
    output wire kws_valid,
    input wire [7:0] frame_size,
    input wire [7:0] frame_overlap,
    input wire [7:0] num_mfcc_coeffs,
    input wire [7:0] num_freqs,
    input wire [4095:0] target_freqs,
    input wire [4095:0] goertzel_coefs
);

    // MFCC module signals
    wire [MFCC_FEATURES*ACTIV_BITS-1:0] mfcc_out;
    wire mfcc_valid;

    // CNN-KWS layers
    wire [ACTIV_BITS-1:0] conv1_out;
    wire conv1_valid;
    wire [ACTIV_BITS-1:0] conv2_out;
    wire conv2_valid;
    wire [ACTIV_BITS-1:0] maxpool_out;
    wire maxpool_valid;
    wire [ACTIV_BITS-1:0] fc1_out;
    wire fc1_valid;
    wire [ACTIV_BITS-1:0] fc2_out;
    wire fc2_valid;
    wire [NUM_KEYWORDS-1:0] softmax_out;
    wire softmax_valid;

    // MFCC module instantiation
    mfcc_accelerator 
     mfcc (
        .clk(clk),
        .rst_n(rst_n),
        .audio_in(audio_in),
        .audio_valid(audio_valid),
        .mfcc_out(mfcc_out),
        .mfcc_valid(mfcc_valid),
        .frame_size(frame_size),
        .frame_overlap(frame_overlap),
        .num_mfcc_coeffs(num_mfcc_coeffs),
        .num_freqs(num_freqs),
        .target_freqs(target_freqs),
        .goertzel_coefs(goertzel_coefs)
    );

// CNN-KWS layers
// Convolutional layer 1
conv2d #(
    .INPUT_WIDTH(MFCC_FEATURES),
    .INPUT_HEIGHT(1),
    .INPUT_CHANNELS(1),
    .KERNEL_WIDTH(3),
    .NUM_FILTERS(32)
) conv1 (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(mfcc_out),
    .data_valid(mfcc_valid),
    .data_out(conv1_out),
    .data_out_valid(conv1_valid)
);

// Convolutional layer 2
conv2d #(
    .INPUT_WIDTH(MFCC_FEATURES),
    .INPUT_HEIGHT(1),
    .INPUT_CHANNELS(1),
    .KERNEL_WIDTH(3),
    .NUM_FILTERS(32)
) conv2 (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(conv1_out),
    .data_valid(conv1_valid),
    .data_out(conv2_out),
    .data_out_valid(conv2_valid)
);

// Max pooling layer
maxpool2d #(
    .INPUT_WIDTH(MFCC_FEATURES),
    .INPUT_HEIGHT(1),
    .INPUT_CHANNELS(32),
    .KERNEL_WIDTH(2)
) maxpool (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(conv2_out),
    .data_valid(conv2_valid),
    .data_out(maxpool_out),
    .data_out_valid(maxpool_valid)
);

// Fully connected layer 1
fully_connected #(
    .INPUT_SIZE(MFCC_FEATURES/2*32),
    .OUTPUT_SIZE(64)
) fc1 (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(maxpool_out),
    .data_valid(maxpool_valid),
    .data_out(fc1_out),
    .data_out_valid(fc1_valid)
);

// Fully connected layer 2 (output layer)
fully_connected #(
    .INPUT_SIZE(64),
    .OUTPUT_SIZE(NUM_KEYWORDS)
) fc2 (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(fc1_out),
    .data_valid(fc1_valid),
    .data_out(fc2_out),
    .data_out_valid(fc2_valid)
);

// Softmax activation
softmax #(
    .INPUT_SIZE(NUM_KEYWORDS)
) softmax (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(fc2_out),
    .data_valid(fc2_valid),
    .data_out(softmax_out),
    .data_out_valid(softmax_valid)
);

// Output assignment
assign kws_result = softmax_out;
assign kws_valid = softmax_valid;

endmodule
