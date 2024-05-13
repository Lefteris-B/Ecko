module mfcc_accel (
    input wire clk,
    input wire rst,
    input wire signed [15:0] audio_sample, // INT16 Q15
    input wire sample_valid,
    output reg signed [15:0] mfcc_feature, // INT16 Q4
    output reg mfcc_valid
);

// Declare signals for interconnecting submodules
wire signed [15:0] hanning_out_real; // INT16 Q15
wire signed [15:0] hanning_out_imag; // INT16 Q15
wire hanning_valid;

wire signed [31:0] periodogram_out; // INT32 Q30
wire periodogram_valid;

wire signed [31:0] pow_out; // INT32 Q30
wire pow_valid;

wire signed [31:0] mel_out; // INT32 Q30
wire mel_valid;

wire signed [15:0] log_out; // INT16 Q11
wire log_valid;

// Instantiate submodules
hanning_window hanning (
    .clk(clk),
    .rst(rst),
    .sample_in(audio_sample),
    .sample_valid(sample_valid),
    .sample_out_real(hanning_out_real),
    .sample_out_imag(hanning_out_imag),
    .sample_out_valid(hanning_valid)
);

periodogram_squared periodogram (
    .clk(clk),
    .rst(rst),
    .sample_in_real(hanning_out_real),
    .sample_in_imag(hanning_out_imag),
    .sample_valid(hanning_valid),
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
