`ifndef FRAMING_WINDOWING_V
`define FRAMING_WINDOWING_V

module framing_windowing (
    input wire clk,
    input wire rst_n,
    input wire [15:0] preemph_out,
    input wire preemph_valid,
    input wire [7:0] frame_size,
    input wire [7:0] frame_overlap,
    output reg [15:0] framed_out,
    output reg framed_valid
);

// Frame buffer
reg [15:0] frame_buffer [0:255];
reg [7:0] frame_counter;
reg frame_buffer_full;

// Constants for Hamming window calculation
localparam integer Q15_ONE = 32'h7FFF;
localparam integer Q15_HALF = 32'h4000;

// Piecewise linear approximation of cosine function for Hamming window
function [15:0] approx_cosine;
    input [7:0] index;
    reg [15:0] result;
begin
    if (index < 64) begin
        result = Q15_ONE - (((Q15_ONE * index) >>> 6) - ((Q15_ONE * index * index) >>> 12));
    end else if (index < 128) begin
        result = ((Q15_ONE * (128 - index)) >>> 6) - ((Q15_ONE * (128 - index) * (128 - index)) >>> 12);
    end else if (index < 192) begin
        result = -((Q15_ONE * (index - 128)) >>> 6) + ((Q15_ONE * (index - 128) * (index - 128)) >>> 12);
    end else begin
        result = -Q15_ONE + (((Q15_ONE * (256 - index)) >>> 6) - ((Q15_ONE * (256 - index) * (256 - index)) >>> 12));
    end
    approx_cosine = result;
end
endfunction

// Framing and windowing logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_counter <= 8'h00;
        frame_buffer_full <= 1'b0;
        framed_out <= 16'h0000;
        framed_valid <= 1'b0;
    end else if (preemph_valid) begin
        // Store pre-emphasized samples in frame buffer
        frame_buffer[frame_counter] <= preemph_out;
        frame_counter <= frame_counter + 1;

        // Check if frame buffer is full
        if (frame_counter == frame_size - 1) begin
            frame_buffer_full <= 1'b1;
            frame_counter <= frame_size - frame_overlap - 1;
        end

        // Apply Hamming window and output framed samples
        if (frame_buffer_full) begin
            reg [15:0] cosine;
            reg [31:0] windowed_sample;

            // Calculate cosine approximation for the current index
            cosine = approx_cosine(frame_counter);

            // Calculate the Hamming window coefficient
            windowed_sample = Q15_ONE - ((Q15_HALF * cosine) >>> 15);

            // Apply the Hamming window coefficient to the framed sample
            framed_out <= (frame_buffer[frame_counter] * windowed_sample) >>> 15;
            framed_valid <= 1'b1;
        end else begin
            framed_valid <= 1'b0;
        end
    end else begin
        framed_valid <= 1'b0;
    end
end

endmodule
`endif