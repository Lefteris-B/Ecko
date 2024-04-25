`include "pre_emphasis.v"
`include "framing.v"
`include "windowing.v"
`include "goertzel.v"
`include "mel_filterbank.v"
`include "logarithm.v"
`include "dct.v"


module mfcc #(
    parameter NUM_MFCC        = 13,
    parameter FRAME_SIZE      = 256,
    parameter FRAME_OVERLAP   = 128,
    parameter NUM_FILTERBANKS = 26,
    parameter INPUT_WIDTH     = 16,
    parameter OUTPUT_WIDTH    = 16,
    parameter FREQ_MIN        = 0,
    parameter FREQ_MAX        = 8000,
    parameter WINDOW_TYPE     = "hamming"
)(
    input                              clk,
    input                              rst_n,
    input  [INPUT_WIDTH-1:0]           audio_in,
    input                              audio_valid,
    input  [NUM_MFCC-1:0][31:0]        config_mfcc_num,
    input  [31:0]                      config_freq_min,
    input  [31:0]                      config_freq_max,
    output [OUTPUT_WIDTH-1:0]          mfcc_out,
    output                             mfcc_valid
);

    // Pre-emphasis
    logic [INPUT_WIDTH-1:0] pre_emphasis_out;
    pre_emphasis #(
        .DATA_WIDTH(INPUT_WIDTH)
    ) pre_emphasis_inst (
        .clk(clk),
        .rst_n(rst_n),
        .audio_in(audio_in),
        .audio_valid(audio_valid),
        .pre_emphasis_out(pre_emphasis_out)
    );

    // Framing
    logic [INPUT_WIDTH-1:0] framed_data[0:FRAME_SIZE-1];
    framing #(
        .DATA_WIDTH(INPUT_WIDTH),
        .FRAME_SIZE(FRAME_SIZE),
        .FRAME_OVERLAP(FRAME_OVERLAP)
    ) framing_inst (
        .clk(clk),
        .rst_n(rst_n),
        .audio_in(pre_emphasis_out),
        .audio_valid(audio_valid),
        .framed_data(framed_data)
    );

    // Windowing
    logic [INPUT_WIDTH-1:0] windowed_data[0:FRAME_SIZE-1];
    windowing #(
        .DATA_WIDTH(INPUT_WIDTH),
        .FRAME_SIZE(FRAME_SIZE),
        .WINDOW_TYPE(WINDOW_TYPE)
    ) windowing_inst (
        .clk(clk),
        .rst_n(rst_n),
        .framed_data(framed_data),
        .windowed_data(windowed_data)
    );

    // Frequency Analysis (Goertzel Algorithm)
    logic [INPUT_WIDTH-1:0] freq_out[0:NUM_FILTERBANKS-1];
    goertzel #(
        .DATA_WIDTH(INPUT_WIDTH),
        .FRAME_SIZE(FRAME_SIZE),
        .NUM_FILTERBANKS(NUM_FILTERBANKS),
        .FREQ_MIN(FREQ_MIN),
        .FREQ_MAX(FREQ_MAX)
    ) goertzel_inst (
        .clk(clk),
        .rst_n(rst_n),
        .windowed_data(windowed_data),
        .freq_out(freq_out),
        .config_freq_min(config_freq_min),
        .config_freq_max(config_freq_max)
    );

    // Mel Filterbank
    logic [INPUT_WIDTH-1:0] filterbank_out[0:NUM_FILTERBANKS-1];
    mel_filterbank #(
        .DATA_WIDTH(INPUT_WIDTH),
        .NUM_FILTERBANKS(NUM_FILTERBANKS)
    ) mel_filterbank_inst (
        .clk(clk),
        .rst_n(rst_n),
        .freq_out(freq_out),
        .filterbank_out(filterbank_out)
    );

    // Logarithm
    logic [INPUT_WIDTH-1:0] log_out[0:NUM_FILTERBANKS-1];
    logarithm #(
        .DATA_WIDTH(INPUT_WIDTH),
        .NUM_FILTERBANKS(NUM_FILTERBANKS)
    ) logarithm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .filterbank_out(filterbank_out),
        .log_out(log_out)
    );

    // DCT
    logic [OUTPUT_WIDTH-1:0] dct_out[0:NUM_MFCC-1];
    dct #(
        .DATA_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .NUM_FILTERBANKS(NUM_FILTERBANKS),
        .NUM_MFCC(NUM_MFCC)
    ) dct_inst (
        .clk(clk),
        .rst_n(rst_n),
        .log_out(log_out),
        .dct_out(dct_out),
        .config_mfcc_num(config_mfcc_num)
    );

    // Output
    assign mfcc_out = dct_out[NUM_MFCC-1];
    assign mfcc_valid = 1'b1; // Adjust based on pipeline stages

endmodule