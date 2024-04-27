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

module cnn_kws_accel (
    input wire clk,
    input wire rst_n,
    input wire [15:0] audio_in,
    input wire audio_valid,
    output wire [NUM_KEYWORDS-1:0] kws_out,
    output wire kws_valid,
    input wire [7:0] frame_size,
    input wire [7:0] frame_overlap,
    input wire [7:0] num_mel_filters,
    input wire [7:0] num_mfcc_coeffs,
    input wire [7:0] num_freqs,
    input wire [15:0] target_freqs [0:255],
    input wire [15:0] goertzel_coefs [0:255]
);

parameter NUM_KEYWORDS = 10; // Number of keywords to detect
parameter WEIGHT_BITS = 8; // Bitwidth for weights
parameter ACTIV_BITS = 8; // Bitwidth for activations

// MFCC module instantiation
wire [31:0] mfcc_out;
wire mfcc_valid;
mfcc_accelerator mfcc (
    .clk(clk),
    .rst_n(rst_n),
    .audio_in(audio_in),
    .audio_valid(audio_valid),
    .mfcc_out(mfcc_out),
    .mfcc_valid(mfcc_valid),
    .frame_size(frame_size),
    .frame_overlap(frame_overlap),
    .num_mel_filters(num_mel_filters),
    .num_mfcc_coeffs(num_mfcc_coeffs),
    .num_freqs(num_freqs),
    .target_freqs(target_freqs),
    .goertzel_coefs(goertzel_coefs)
);

// CNN-KWS layers
// Convolutional layer 1
wire [ACTIV_BITS-1:0] conv1_out [0:31];
wire conv1_valid;
conv2d #(
    .INPUT_WIDTH(num_mfcc_coeffs),
    .INPUT_HEIGHT(1),
    .INPUT_CHANNELS(1),
    .KERNEL_SIZE(3),
    .NUM_FILTERS(32),
    .WEIGHT_BITS(WEIGHT_BITS),
    .ACTIV_BITS(ACTIV_BITS)
) conv1 (
    .clk(clk),
    .rst_n(rst_n),
    .input_data(mfcc_out),
    .input_valid(mfcc_valid),
    .output_data(conv1_out),
    .output_valid(conv1_valid)
);

// Convolutional layer 2
wire [ACTIV_BITS-1:0] conv2_out [0:31];
wire conv2_valid;
conv2d #(
    .INPUT_WIDTH(num_mfcc_coeffs),
    .INPUT_HEIGHT(1),
    .INPUT_CHANNELS(32),
    .KERNEL_SIZE(3),
    .NUM_FILTERS(32),
    .WEIGHT_BITS(WEIGHT_BITS),
    .ACTIV_BITS(ACTIV_BITS)
) conv2 (
    .clk(clk),
    .rst_n(rst_n),
    .input_data(conv1_out),
    .input_valid(conv1_valid),
    .output_data(conv2_out),
    .output_valid(conv2_valid)
);

// Max pooling layer
wire [ACTIV_BITS-1:0] maxpool_out [0:15];
wire maxpool_valid;
maxpool2d #(
    .INPUT_WIDTH(num_mfcc_coeffs),
    .INPUT_HEIGHT(1),
    .INPUT_CHANNELS(32),
    .POOL_SIZE(2),
    .ACTIV_BITS(ACTIV_BITS)
) maxpool (
    .clk(clk),
    .rst_n(rst_n),
    .input_data(conv2_out),
    .input_valid(conv2_valid),
    .output_data(maxpool_out),
    .output_valid(maxpool_valid)
);

// Fully connected layer 1
wire [ACTIV_BITS-1:0] fc1_out [0:63];
wire fc1_valid;
fully_connected #(
    .INPUT_SIZE(16*32),
    .OUTPUT_SIZE(64),
    .WEIGHT_BITS(WEIGHT_BITS),
    .ACTIV_BITS(ACTIV_BITS)
) fc1 (
    .clk(clk),
    .rst_n(rst_n),
    .input_data(maxpool_out),
    .input_valid(maxpool_valid),
    .output_data(fc1_out),
    .output_valid(fc1_valid)
);

// Fully connected layer 2 (output layer)
wire [ACTIV_BITS-1:0] fc2_out [0:NUM_KEYWORDS-1];
wire fc2_valid;
fully_connected #(
    .INPUT_SIZE(64),
    .OUTPUT_SIZE(NUM_KEYWORDS),
    .WEIGHT_BITS(WEIGHT_BITS),
    .ACTIV_BITS(ACTIV_BITS)
) fc2 (
    .clk(clk),
    .rst_n(rst_n),
    .input_data(fc1_out),
    .input_valid(fc1_valid),
    .output_data(fc2_out),
    .output_valid(fc2_valid)
);

// Softmax activation
wire [NUM_KEYWORDS-1:0] softmax_out;
wire softmax_valid;
softmax #(
    .INPUT_SIZE(NUM_KEYWORDS),
    .ACTIV_BITS(ACTIV_BITS)
) softmax (
    .clk(clk),
    .rst_n(rst_n),
    .input_data(fc2_out),
    .input_valid(fc2_valid),
    .output_data(softmax_out),
    .output_valid(softmax_valid)
);

// Output assignment
assign kws_out = softmax_out;
assign kws_valid = softmax_valid;

endmodule
