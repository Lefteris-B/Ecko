`ifndef MFCC_ACCELERATOR_V
`define MFCC_ACCELERATOR_V

module mfcc_accelerator #(
    parameter MFCC_FEATURES = 40,
    parameter ACTIV_BITS = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [15:0] audio_in,
    input wire audio_valid,
    output reg [MFCC_FEATURES*ACTIV_BITS-1:0] mfcc_out,
    output reg mfcc_valid,
    input wire [7:0] frame_size,
    input wire [7:0] frame_overlap,
    input wire [7:0] num_mfcc_coeffs,
    input wire [7:0] goertzel_coefs,
    output reg goertzel_coefs_start,
    output wire goertzel_coefs_valid,
    output wire goertzel_coefs_done
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
    wire [MFCC_FEATURES*ACTIV_BITS-1:0] dct_out;
    wire dct_valid;

    // Instantiate sub-modules

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

    // Control logic for Goertzel coefficients transfer
    localparam IDLE = 2'b00;
    localparam START_TRANSFER = 2'b01;
    localparam WAIT_TRANSFER = 2'b10;

    reg [1:0] state;
    reg goertzel_coefs_start_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            goertzel_coefs_start_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // Initiate the transfer
                    state <= START_TRANSFER;
                end
                START_TRANSFER: begin
                    // Set the start signal
                    goertzel_coefs_start_reg <= 1;
                    state <= WAIT_TRANSFER;
                end
                WAIT_TRANSFER: begin
                    // Clear the start signal
                    goertzel_coefs_start_reg <= 0;
                    // Wait for the transfer to complete
                    if (goertzel_coefs_done) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    assign goertzel_coefs_start = goertzel_coefs_start_reg;

    // Discrete Fourier Transform (DFT) using Goertzel's algorithm
    // Instantiate the modified goertzel_dft module
    goertzel_dft dft (
        .clk(clk),
        .rst_n(rst_n),
        .framed_out(framed_out),
        .framed_valid(framed_valid),
        .goertzel_coefs(goertzel_coefs),
        .goertzel_coefs_start(goertzel_coefs_start),
        .goertzel_coefs_valid(goertzel_coefs_valid),
        .goertzel_coefs_done(goertzel_coefs_done),
        .dft_out(dft_out),
        .dft_valid(dft_valid)
    );

 // Instantiate the mel_filterbank module
    mel_filterbank #(
        .NUM_MEL_FILTERS(40),
        .NUM_DFT_POINTS(256),
        .COEF_WIDTH(16),
        .ACCUMULATOR_WIDTH(32)
    ) mel_fbank (
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
        .num_mfcc_coeffs(num_mfcc_coeffs[4:0]),
        .dct_out(dct_out),
        .dct_valid(dct_valid)
    );


    // Output assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mfcc_out <= 'b0;
        mfcc_valid <= 1'b0;
    end else begin
        mfcc_out <= dct_out;
        mfcc_valid <= dct_valid;
    end
end

endmodule
`endif
