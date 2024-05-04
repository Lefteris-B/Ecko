`ifndef MEL_FILTERBANK_V
`define MEL_FILTERBANK_V

module mel_filterbank #(
    parameter NUM_MEL_FILTERS = 40,
    parameter NUM_DFT_POINTS = 256,
    parameter COEF_WIDTH = 16,
    parameter ACCUMULATOR_WIDTH = 32,
    parameter SAMPLING_FREQ = 16000,
    parameter NUM_SEGMENTS = 4,
    parameter SEGMENT_BOUNDARIES = {16'h4000, 16'h2000, 16'h1000, 16'h0000},
    parameter SEGMENT_SLOPES = {16'h0200, 16'h0400, 16'h0800, 16'h1000},
    parameter SEGMENT_INTERCEPTS = {16'h1000, 16'h0800, 16'h0400, 16'h0000}
) (
    input wire clk,
    input wire rst_n,
    input wire [31:0] dft_out,
    input wire dft_valid,
    output reg [ACCUMULATOR_WIDTH-1:0] mel_fbank_out,
    output reg mel_fbank_valid
);

// Registers for accumulating filterbank energies
reg [ACCUMULATOR_WIDTH-1:0] mel_accumulator;

// Counters for iterating over mel-scale filters and DFT points
reg [$clog2(NUM_MEL_FILTERS)-1:0] mel_filter_cnt;
reg [$clog2(NUM_DFT_POINTS)-1:0] dft_point_cnt;

// Mel-scale filterbank computation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mel_filter_cnt <= 0;
        dft_point_cnt <= 0;
        mel_fbank_out <= 0;
        mel_fbank_valid <= 0;
        mel_accumulator <= 0;
    end else begin
        if (dft_valid) begin
            // Compute the mel-scale filter coefficient using piecewise linear approximation
            reg [COEF_WIDTH-1:0] mel_coef;
            mel_coef = compute_mel_coef_approx(dft_point_cnt);

            // Multiply DFT output with the corresponding filter coefficient
            mel_accumulator <= mel_accumulator + (dft_out * mel_coef);

            // Increment DFT point counter
            if (dft_point_cnt == NUM_DFT_POINTS - 1) begin
                dft_point_cnt <= 0;
                // Increment mel-scale filter counter
                if (mel_filter_cnt == NUM_MEL_FILTERS - 1) begin
                    mel_filter_cnt <= 0;
                    // Output the accumulated filterbank energy
                    mel_fbank_out <= mel_accumulator;
                    mel_fbank_valid <= 1;
                    // Reset the accumulator for the next frame
                    mel_accumulator <= 0;
                end else begin
                    mel_filter_cnt <= mel_filter_cnt + 1;
                    mel_fbank_out <= 0;
                    mel_fbank_valid <= 0;
                end
            end else begin
                dft_point_cnt <= dft_point_cnt + 1;
                mel_fbank_out <= 0;
                mel_fbank_valid <= 0;
            end
        end else begin
            mel_fbank_out <= 0;
            mel_fbank_valid <= 0;
        end
    end
end

// Function to compute mel-scale filter coefficients using piecewise linear approximation
function [COEF_WIDTH-1:0] compute_mel_coef_approx;
    input [$clog2(NUM_DFT_POINTS)-1:0] dft_idx;
    
    // Convert DFT index to frequency in Hz
    real freq_hz;
    freq_hz = (dft_idx * SAMPLING_FREQ) / NUM_DFT_POINTS;
    
    // Piecewise linear approximation of mel frequency
    reg [COEF_WIDTH-1:0] mel_freq_approx;
    reg [$clog2(NUM_SEGMENTS)-1:0] seg_idx;
    
    seg_idx = 0;
    for (int i = 0; i < NUM_SEGMENTS-1; i = i + 1) begin
        if (freq_hz >= SEGMENT_BOUNDARIES[i*16 +: 16])
            seg_idx = i + 1;
    end
    
    mel_freq_approx = (SEGMENT_SLOPES[seg_idx*16 +: 16] * freq_hz) + SEGMENT_INTERCEPTS[seg_idx*16 +: 16];
    
    // Calculate the mel-scale filter coefficient
    reg [COEF_WIDTH-1:0] mel_coef;
    if (mel_filter_cnt == 0) begin
        if (dft_idx < (NUM_DFT_POINTS / NUM_MEL_FILTERS)) begin
            mel_coef = COEF_WIDTH'h7FFF - ((mel_freq_approx * COEF_WIDTH'h7FFF) / (2595 / NUM_MEL_FILTERS));
        end else begin
            mel_coef = 0;
        end
    end else if (mel_filter_cnt == NUM_MEL_FILTERS - 1) begin
        if (dft_idx >= ((NUM_MEL_FILTERS - 1) * (NUM_DFT_POINTS / NUM_MEL_FILTERS))) begin
            mel_coef = ((mel_freq_approx - ((NUM_MEL_FILTERS - 1) * (2595 / NUM_MEL_FILTERS))) * COEF_WIDTH'h7FFF) / (2595 / NUM_MEL_FILTERS);
        end else begin
            mel_coef = 0;
        end
    end else begin
        real left_mel, right_mel;
        left_mel = (mel_filter_cnt * (2595 / NUM_MEL_FILTERS));
        right_mel = ((mel_filter_cnt + 1) * (2595 / NUM_MEL_FILTERS));
        
        if (mel_freq_approx >= left_mel && mel_freq_approx < right_mel) begin
            mel_coef = ((mel_freq_approx - left_mel) * COEF_WIDTH'h7FFF) / (2595 / NUM_MEL_FILTERS);
        end else begin
            mel_coef = 0;
        end
    end
    
    compute_mel_coef_approx = mel_coef;
endfunction

endmodule
`endif