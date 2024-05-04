module log_approx #(
    parameter NUM_MELS = 40,
    parameter MEL_ENERGY_WIDTH = 32,
    parameter LOG_MEL_ENERGY_WIDTH = 16,
    parameter NUM_SEGMENTS = 4,
    parameter SEGMENT_BOUNDARIES = {32'h40000000, 32'h20000000, 32'h10000000, 32'h08000000},
    parameter SEGMENT_SLOPES = {16'h0100, 16'h0200, 16'h0400, 16'h0800},
    parameter SEGMENT_INTERCEPTS = {16'h0000, 16'h0100, 16'h0200, 16'h0300}
)(
    input wire clk,
    input wire rst,
    input wire [MEL_ENERGY_WIDTH-1:0] mel_energies [0:NUM_MELS-1],
    output reg [LOG_MEL_ENERGY_WIDTH-1:0] log_mel_energies [0:NUM_MELS-1]
);

// Fixed-point parameters
localparam FP_FRAC_BITS = 10;
localparam FP_INT_BITS = MEL_ENERGY_WIDTH - FP_FRAC_BITS;

// Pipeline registers
reg [MEL_ENERGY_WIDTH-1:0] mel_energies_pipe [0:NUM_MELS-1];
reg [$clog2(NUM_SEGMENTS)-1:0] segment_indices [0:NUM_MELS-1];

// Pipeline stage 1: Segment index calculation
always @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_MELS; i = i + 1) begin
            mel_energies_pipe[i] <= 0;
            segment_indices[i] <= 0;
        end
    end else begin
        for (int i = 0; i < NUM_MELS; i = i + 1) begin
            mel_energies_pipe[i] <= mel_energies[i];
            segment_indices[i] <= get_segment_index(mel_energies[i]);
        end
    end
end

// Pipeline stage 2: Logarithm approximation
always @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_MELS; i = i + 1) begin
            log_mel_energies[i] <= 0;
        end
    end else begin
        for (int i = 0; i < NUM_MELS; i = i + 1) begin
            log_mel_energies[i] <= log_approx_segment(mel_energies_pipe[i], segment_indices[i]);
        end
    end
end

// Function to determine the segment index based on the mel-energy value
function [$clog2(NUM_SEGMENTS)-1:0] get_segment_index;
    input [MEL_ENERGY_WIDTH-1:0] mel_energy;
    
    for (int i = 0; i < NUM_SEGMENTS; i = i + 1) begin
        if (mel_energy >= SEGMENT_BOUNDARIES[i*32 +: 32]) begin
            get_segment_index = i;
            return;
        end
    end
    
    get_segment_index = NUM_SEGMENTS - 1;
endfunction

// Function to calculate the logarithm approximation for a given segment
function [LOG_MEL_ENERGY_WIDTH-1:0] log_approx_segment;
    input [MEL_ENERGY_WIDTH-1:0] mel_energy;
    input [$clog2(NUM_SEGMENTS)-1:0] segment_index;
    
    reg [MEL_ENERGY_WIDTH-1:0] shifted_mel_energy;
    reg [MEL_ENERGY_WIDTH-1:0] segment_boundary;
    reg [LOG_MEL_ENERGY_WIDTH-1:0] slope;
    reg [LOG_MEL_ENERGY_WIDTH-1:0] intercept;
    
    segment_boundary = SEGMENT_BOUNDARIES[segment_index*32 +: 32];
    slope = SEGMENT_SLOPES[segment_index*16 +: 16];
    intercept = SEGMENT_INTERCEPTS[segment_index*16 +: 16];
    
    shifted_mel_energy = mel_energy - segment_boundary;
    log_approx_segment = (shifted_mel_energy[MEL_ENERGY_WIDTH-1:FP_FRAC_BITS] * slope) + intercept;
endfunction

endmodule