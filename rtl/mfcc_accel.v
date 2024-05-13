module mfcc_accel (
    input wire clk,
    input wire rst,
    input wire [15:0] audio_sample,
    input wire sample_valid,
    output reg [15:0] mfcc_feature,
    output reg mfcc_valid
);

// Declare signals for interconnecting submodules
wire [15:0] hamming_out;
wire hamming_valid;
wire [31:0] periodogram_out;
wire periodogram_valid;
wire [31:0] pow_out;
wire pow_valid;
wire [31:0] mel_out;
wire mel_valid;
wire [15:0] log_out;
wire log_valid;

// Instantiate submodules
hamming_window hamming (
    .clk(clk),
    .rst(rst),
    .sample_in(audio_sample),
    .sample_valid(sample_valid),
    .sample_out(hamming_out),
    .sample_out_valid(hamming_valid)
);

periodogram_squared periodogram (
    .clk(clk),
    .rst(rst),
    .sample_in(hamming_out),
    .sample_valid(hamming_valid),
    .periodogram_out(periodogram_out),
    .periodogram_valid(periodogram_valid)
);

pow_module pow (
    .clk(clk),
    .rst(rst),
    .data_in(periodogram_out),
    .data_valid(periodogram_valid),
    .data_out(pow_out),
    .data_out_valid(pow_valid)
);

mel_filterbank mel (
    .clk(clk),
    .rst(rst),
    .data_in(pow_out),
    .data_valid(pow_valid),
    .mel_out(mel_out),
    .mel_valid(mel_valid)
);

log_module log (
    .clk(clk),
    .rst(rst),
    .data_in(mel_out),
    .data_valid(mel_valid),
    .log_out(log_out),
    .log_valid(log_valid)
);

dct_module dct (
    .clk(clk),
    .rst(rst),  
    .data_in(log_out),
    .data_valid(log_valid),
    .dct_out(mfcc_feature),
    .dct_valid(mfcc_valid)
);

endmodule
