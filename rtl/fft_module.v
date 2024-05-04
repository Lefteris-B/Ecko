module fft_module #(
    parameter FRAME_SIZE = 256,
    parameter SAMPLE_WIDTH = 16,
    parameter OUTPUT_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [SAMPLE_WIDTH-1:0] sample_in,
    input wire sample_valid,
    output reg [OUTPUT_WIDTH-1:0] fft_real,
    output reg [OUTPUT_WIDTH-1:0] fft_imag,
    output reg fft_valid
);

localparam STAGES = $clog2(FRAME_SIZE);
localparam TWIDDLE_WIDTH = 16;

reg [SAMPLE_WIDTH-1:0] input_buffer [0:FRAME_SIZE-1];
reg [$clog2(FRAME_SIZE)-1:0] input_counter;

reg [SAMPLE_WIDTH-1:0] stage_buffer [0:FRAME_SIZE-1];
reg [$clog2(FRAME_SIZE)-1:0] stage_counter;

wire [TWIDDLE_WIDTH-1:0] twiddle_real [0:FRAME_SIZE/2-1];
wire [TWIDDLE_WIDTH-1:0] twiddle_imag [0:FRAME_SIZE/2-1];

// Precalculated twiddle factors (example values)
assign twiddle_real[0] = 16'h7FFF;
assign twiddle_imag[0] = 16'h0000;
// ... assign other twiddle factors ...

always @(posedge clk) begin
    if (rst) begin
        input_counter <= 0;
        stage_counter <= 0;
        fft_valid <= 0;
    end else begin
        if (sample_valid) begin
            input_buffer[input_counter] <= sample_in;
            input_counter <= input_counter + 1;

            if (input_counter == FRAME_SIZE-1) begin
                stage_counter <= 0;
                input_counter <= 0;
                fft_valid <= 0;
            end
        end

        if (input_counter == FRAME_SIZE) begin
            stage_buffer <= input_buffer;
            stage_counter <= 0;
        end else if (stage_counter < STAGES) begin
            stage_buffer <= butterfly(stage_buffer, stage_counter);
            stage_counter <= stage_counter + 1;
        end else begin
            fft_real <= stage_buffer[0][SAMPLE_WIDTH-1:SAMPLE_WIDTH-OUTPUT_WIDTH];
            fft_imag <= stage_buffer[FRAME_SIZE/2][SAMPLE_WIDTH-1:SAMPLE_WIDTH-OUTPUT_WIDTH];
            fft_valid <= 1;
        end
    end
end

function [SAMPLE_WIDTH-1:0] butterfly;
    input [SAMPLE_WIDTH-1:0] a, b;
    input [$clog2(FRAME_SIZE)-1:0] stage;
    reg [SAMPLE_WIDTH-1:0] sum, diff;
    reg [TWIDDLE_WIDTH-1:0] twiddle_r, twiddle_i;
    reg [2*SAMPLE_WIDTH-1:0] mult_real, mult_imag;
begin
    twiddle_r = twiddle_real[stage];
    twiddle_i = twiddle_imag[stage];
    
    mult_real = (b * twiddle_r) >>> TWIDDLE_WIDTH;
    mult_imag = (b * twiddle_i) >>> TWIDDLE_WIDTH;
    
    sum = a + mult_real;
    diff = a - mult_real;
    
    butterfly[0] = sum;
    butterfly[1] = diff;
end
endfunction

endmodule