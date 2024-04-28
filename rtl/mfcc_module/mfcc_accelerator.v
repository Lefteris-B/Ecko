module mfcc_accelerator (
    input wire clk,
    input wire rst_n,
    input wire [15:0] audio_in,
    input wire audio_valid,
    output reg [31:0] mfcc_out,
    output reg mfcc_valid,
    input wire [7:0] frame_size,
    input wire [7:0] frame_overlap,
    input wire [7:0] num_mfcc_coeffs,
    input wire [7:0] num_freqs,
    input wire [4095:0] target_freqs,
    input wire [4095:0] goertzel_coefs
);

// Signal declarations
wire [15:0] preemph_out;
wire preemph_valid;
wire [15:0] framed_out;
wire framed_valid;
wire [31:0] dft_out;
wire dft_valid;
wire [31:0] mel_fbank_out;
wire mel_fbank_valid;
wire [31:0] log_out;
wire log_valid;
wire [31:0] dct_out;
wire dct_valid;

// Pre-emphasis filtering
preemphasis_filter preemph (
    .clk(clk),
    .rst_n(rst_n),
    .audio_in(audio_in),
    .audio_valid(audio_valid),
    .preemph_out(preemph_out),
    .preemph_valid(preemph_valid)
);

// Framing and windowing
framing_windowing framing (
    .clk(clk),
    .rst_n(rst_n),
    .preemph_out(preemph_out),
    .preemph_valid(preemph_valid),
    .frame_size(frame_size),
    .frame_overlap(frame_overlap),
    .framed_out(framed_out),
    .framed_valid(framed_valid)
);

// Discrete Fourier Transform (DFT) using Goertzel's algorithm
goertzel_dft dft (
    .clk(clk),
    .rst_n(rst_n),
    .framed_out(framed_out),
    .framed_valid(framed_valid),
    .num_freqs(num_freqs),
    .target_freqs(target_freqs),
    .goertzel_coefs(goertzel_coefs),
    .dft_out(dft_out),
    .dft_valid(dft_valid)
);

// Mel-scale filterbank application
mel_filterbank mel_fbank (
    .clk(clk),
    .rst_n(rst_n),
    .dft_out(dft_out),
    .dft_valid(dft_valid),
    .mel_fbank_out(mel_fbank_out),
    .mel_fbank_valid(mel_fbank_valid)
);

// Logarithm computation
logarithm_comp log_comp (
    .clk(clk),
    .rst_n(rst_n),
    .mel_fbank_out(mel_fbank_out),
    .mel_fbank_valid(mel_fbank_valid),
    .log_out(log_out),
    .log_valid(log_valid)
);

// Discrete Cosine Transform (DCT)
dct_comp dct (
    .clk(clk),
    .rst_n(rst_n),
    .log_out(log_out),
    .log_valid(log_valid),
    .num_mfcc_coeffs(num_mfcc_coeffs),
    .dct_out(dct_out),
    .dct_valid(dct_valid)
);

// Output assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mfcc_out <= 32'h0;
        mfcc_valid <= 1'b0;
    end else begin
        mfcc_out <= dct_out;
        mfcc_valid <= dct_valid;
    end
end

endmodule