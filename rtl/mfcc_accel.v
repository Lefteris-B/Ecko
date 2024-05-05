module mfcc (
  input wire clk,
  input wire rst,
  input wire [15:0] audio_sample,
  input wire sample_valid,
  output reg [3:0] mfcc_feature,
  output reg mfcc_valid
);

  // Declare signals for interconnecting submodules
  wire [15:0] hamming_out;
  wire [15:0] periodogram_out;
  wire [31:0] pow_out;
  wire [31:0] mel_out;
  wire [10:0] log_out;

  // Instantiate submodules
  hamming_window hamming (
    .clk(clk),
    .rst(rst),
    .sample_in(audio_sample),
    .sample_valid(sample_valid),
    .sample_out(hamming_out)
  );

  periodogram_squared periodogram (
    .clk(clk),
    .rst(rst),
    .sample_in(hamming_out),
    .sample_valid(sample_valid),
    .periodogram_out(periodogram_out)
  );

  pow_module pow (
    .clk(clk),
    .rst(rst),
    .data_in(periodogram_out),
    .data_valid(sample_valid),
    .data_out(pow_out)
  );

  mel_filterbank mel (
    .clk(clk),
    .rst(rst),
    .data_in(pow_out),
    .data_valid(sample_valid),
    .mel_out(mel_out)
  );

  log_module log (
    .clk(clk),
    .rst(rst),
    .data_in(mel_out),
    .data_valid(sample_valid),
    .log_out(log_out)
  );

  dct_module dct (
    .clk(clk),
    .rst(rst),
    .data_in(log_out),
    .data_valid(sample_valid),
    .mfcc_out(mfcc_feature),
    .mfcc_valid(mfcc_valid)
  );

endmodule