module mfcc_accel #(
    // Parameter definitions
    parameter SAMPLE_WIDTH = 16,
    parameter FRAME_SIZE = 256,
    parameter FFT_SIZE = 256,
    parameter NUM_MELS = 40,
    parameter NUM_MFCCS = 13
)(
    // Input ports
    input wire clk,
    input wire rst,
    input wire [SAMPLE_WIDTH-1:0] audio_in,
    input wire audio_valid,
    input wire [7:0] config_reg,

    // Output ports
    output wire [15:0] mfcc_out,
    output wire mfcc_valid,
    output wire busy
);

    // Interconnect signals
    wire [SAMPLE_WIDTH-1:0] framed_audio;
    wire framed_audio_valid;
    wire [SAMPLE_WIDTH-1:0] windowed_audio;
    wire windowed_audio_valid;
    wire [31:0] fft_out;
    wire fft_valid;
    wire [15:0] mel_energies [0:NUM_MELS-1];
    wire mel_energies_valid;
    wire [15:0] log_mel_energies [0:NUM_MELS-1];
    wire log_mel_energies_valid;

    // Control signals
    reg start;
    reg [3:0] state;

    // Instantiate submodules
    audio_framing #(
        .SAMPLE_WIDTH(SAMPLE_WIDTH),
        .FRAME_SIZE(FRAME_SIZE)
    ) audio_framing_inst (
        .clk(clk),
        .rst(rst),
        .audio_sample(audio_in),
        .sample_valid(audio_valid),
        .framed_audio(framed_audio),
        .frame_valid(framed_audio_valid)
    );

    hamming_window #(
        .SAMPLE_WIDTH(SAMPLE_WIDTH),
        .FRAME_SIZE(FRAME_SIZE)
    ) hamming_window_inst (
        .clk(clk),
        .rst(rst),
        .audio_frame(framed_audio),
        .frame_valid(framed_audio_valid),
        .windowed_frame(windowed_audio),
        .windowed_frame_valid(windowed_audio_valid)
    );

    fft_module #(
        .FFT_SIZE(FFT_SIZE)
    ) fft_module_inst (
        .clk(clk),
        .rst(rst),
        .fft_in(windowed_audio),
        .fft_in_valid(windowed_audio_valid),
        .fft_out(fft_out),
        .fft_out_valid(fft_valid)
    );

    mel_filterbank #(
        .FFT_SIZE(FFT_SIZE),
        .NUM_MELS(NUM_MELS)
    ) mel_filterbank_inst (
        .clk(clk),
        .rst(rst),
        .fft_out(fft_out),
        .fft_valid(fft_valid),
        .mel_energies(mel_energies),
        .mel_energies_valid(mel_energies_valid)
    );

    log_approx #(
        .NUM_MELS(NUM_MELS)
    ) log_approx_inst (
        .clk(clk),
        .rst(rst),
        .mel_energies(mel_energies),
        .mel_energies_valid(mel_energies_valid),
        .log_mel_energies(log_mel_energies),
        .log_mel_energies_valid(log_mel_energies_valid)
    );

    dct_module #(
        .NUM_MELS(NUM_MELS),
        .NUM_MFCCS(NUM_MFCCS)
    ) dct_module_inst (
        .clk(clk),
        .rst(rst),
        .log_mel_energies(log_mel_energies),
        .log_mel_energies_valid(log_mel_energies_valid),
        .mfcc_out(mfcc_out),
        .mfcc_valid(mfcc_valid)
    );

    // Control logic
    always @(posedge clk) begin
        if (rst) begin
            start <= 0;
            state <= 0;
        end else begin
            case (state)
                0: begin
                    if (config_reg[0]) begin
                        start <= 1;
                        state <= 1;
                    end
                end
                1: begin
                    if (framed_audio_valid) begin
                        state <= 2;
                    end
                end
                2: begin
                    if (windowed_audio_valid) begin
                        state <= 3;
                    end
                end
                3: begin
                    if (fft_valid) begin
                        state <= 4;
                    end
                end
                4: begin
                    if (mel_energies_valid) begin
                        state <= 5;
                    end
                end
                5: begin
                    if (log_mel_energies_valid) begin
                        state <= 6;
                    end
                end
                6: begin
                    if (mfcc_valid) begin
                        start <= 0;
                        state <= 0;
                    end
                end
            endcase
        end
    end

    // Busy signal
    assign busy = start;

endmodule