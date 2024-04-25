// Mel Filterbank Module
module mel_filterbank #(
    parameter DATA_WIDTH   = 16,
    parameter NUM_FILTERS  = 26,
    parameter FREQ_WIDTH   = 16,
    parameter SAMPLE_RATE  = 16000,
    parameter FFT_SIZE     = 256
)(
    input                                      clk,
    input                                      rst_n,
    input  signed [DATA_WIDTH-1:0]             power_spectrum [0:FFT_SIZE-1],
    input                                      power_valid,
    output signed [DATA_WIDTH+$clog2(FFT_SIZE)-1:0] mel_out [0:NUM_FILTERS-1],
    output                                     mel_valid
);

    // Fixed-point representation of constants
    localparam FIXED_WIDTH = 32;
    localparam FIXED_FRAC_BITS = 20;

    // Mel scale frequency boundaries
    real mel_low;
    real mel_high;
    real mel_step;
    real mel_freq_low;
    real mel_freq_high;

    // FFT bin indices corresponding to mel frequency boundaries
    integer fft_bin_low [0:NUM_FILTERS-1];
    integer fft_bin_high [0:NUM_FILTERS-1];

    // Triangular filter coefficients
    reg [FIXED_WIDTH-1:0] filter_coeff [0:NUM_FILTERS-1][0:FFT_SIZE-1];

    // Compute mel scale frequency boundaries
    initial begin
        mel_low = 2595 * $log10(1 + 0 / 700.0);
        mel_high = 2595 * $log10(1 + (SAMPLE_RATE / 2) / 700.0);
        mel_step = (mel_high - mel_low) / (NUM_FILTERS + 1);

        for (integer i = 0; i < NUM_FILTERS+2; i = i + 1) begin
            mel_freq_low = 700 * ($pow(10, (mel_low + i * mel_step) / 2595) - 1);
            mel_freq_high = 700 * ($pow(10, (mel_low + (i+1) * mel_step) / 2595) - 1);

            if (i < NUM_FILTERS) begin
                fft_bin_low[i] = $rtoi(mel_freq_low * FFT_SIZE / SAMPLE_RATE);
                fft_bin_high[i] = $rtoi(mel_freq_high * FFT_SIZE / SAMPLE_RATE);
            end
        end
    end

    // Generate triangular filter coefficients
    integer i, j;
    initial begin
        for (i = 0; i < NUM_FILTERS; i = i + 1) begin
            for (j = 0; j < FFT_SIZE; j = j + 1) begin
                if (j < fft_bin_low[i] || j > fft_bin_high[i]) begin
                    filter_coeff[i][j] = 0;
                end else if (j >= fft_bin_low[i] && j <= (fft_bin_low[i] + fft_bin_high[i])/2) begin
                    filter_coeff[i][j] = $rtoi(((j - fft_bin_low[i]) * (1 << FIXED_FRAC_BITS)) / (((fft_bin_low[i] + fft_bin_high[i])/2) - fft_bin_low[i]));
                end else begin
                    filter_coeff[i][j] = $rtoi(((fft_bin_high[i] - j) * (1 << FIXED_FRAC_BITS)) / (fft_bin_high[i] - ((fft_bin_low[i] + fft_bin_high[i])/2)));
                end
            end
        end
    end

    // Apply mel filters to power spectrum
    reg signed [DATA_WIDTH+$clog2(FFT_SIZE)-1:0] mel_acc [0:NUM_FILTERS-1];
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                mel_acc[k] <= 0;
            end
        end else if (power_valid) begin
            for (k = 0; k < NUM_FILTERS; k = k + 1) begin
                mel_acc[k] <= 0;
                for (j = 0; j < FFT_SIZE; j = j + 1) begin
                    mel_acc[k] <= mel_acc[k] + ((power_spectrum[j] * filter_coeff[k][j]) >>> FIXED_FRAC_BITS);
                end
            end
        end
    end

    // Output mel spectrum and valid signal
    assign mel_out = mel_acc;
    assign mel_valid = power_valid;

endmodule