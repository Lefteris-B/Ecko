`ifndef MEL_FILTERBANK_V
`define MEL_FILTERBANK_V

module mel_filterbank #(
    parameter NUM_MEL_FILTERS = 40,
    parameter NUM_DFT_POINTS = 256,
    parameter COEF_WIDTH = 16,
    parameter ACCUMULATOR_WIDTH = 32,
    parameter SAMPLING_FREQ = 16000
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
            // Compute the mel-scale filter coefficient on-the-fly
            reg [COEF_WIDTH-1:0] mel_coef;
            mel_coef = compute_mel_coef(mel_filter_cnt, dft_point_cnt);

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

// Function to compute mel-scale filter coefficients on-the-fly
function [COEF_WIDTH-1:0] compute_mel_coef;
    input [$clog2(NUM_MEL_FILTERS)-1:0] mel_idx;
    input [$clog2(NUM_DFT_POINTS)-1:0] dft_idx;
    
    // Constants for the piecewise linear approximation
    parameter MEL_BREAK_FREQ_HZ = 1000;
    parameter MEL_HIGH_FREQ_Q = 2595;
    
    // Convert DFT index to frequency in Hz
    real freq_hz;
    freq_hz = (dft_idx * SAMPLING_FREQ) / NUM_DFT_POINTS;
    
    // Piecewise linear approximation of mel frequency
    real mel_freq;
    if (freq_hz < MEL_BREAK_FREQ_HZ) begin
        mel_freq = (freq_hz / MEL_BREAK_FREQ_HZ) * 2595;
    end else begin
        mel_freq = MEL_HIGH_FREQ_Q * $ln(1 + (freq_hz / 700));
    end
    
    // Calculate the mel-scale filter coefficient
    real mel_coef;
    if (mel_idx == 0) begin
        if (dft_idx < (NUM_DFT_POINTS / NUM_MEL_FILTERS)) begin
            mel_coef = 1 - (mel_freq / (2595 / NUM_MEL_FILTERS));
        end else begin
            mel_coef = 0;
        end
    end else if (mel_idx == NUM_MEL_FILTERS - 1) begin
        if (dft_idx >= ((NUM_MEL_FILTERS - 1) * (NUM_DFT_POINTS / NUM_MEL_FILTERS))) begin
            mel_coef = (mel_freq - ((NUM_MEL_FILTERS - 1) * (2595 / NUM_MEL_FILTERS))) / (2595 / NUM_MEL_FILTERS);
        end else begin
            mel_coef = 0;
        end
    end else begin
        real left_mel, right_mel;
        left_mel = (mel_idx * (2595 / NUM_MEL_FILTERS));
        right_mel = ((mel_idx + 1) * (2595 / NUM_MEL_FILTERS));
        
        if (mel_freq >= left_mel && mel_freq < right_mel) begin
            mel_coef = (mel_freq - left_mel) / (2595 / NUM_MEL_FILTERS);
        end else begin
            mel_coef = 0;
        end
    end
    
    // Convert the real-valued coefficient to fixed-point representation
    compute_mel_coef = mel_coef * (2 ** (COEF_WIDTH - 1));
endfunction

endmodule
`endif