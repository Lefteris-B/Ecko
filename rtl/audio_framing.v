module audio_framing #(
    parameter SAMPLE_WIDTH = 16,
    parameter FRAME_SIZE = 256,
    parameter HOP_SIZE = 128
)(
    input wire clk,
    input wire rst,
    input wire [SAMPLE_WIDTH-1:0] audio_sample,
    input wire sample_valid,
    output reg [SAMPLE_WIDTH-1:0] framed_audio,
    output reg frame_valid
);

localparam BUFFER_SIZE = FRAME_SIZE + HOP_SIZE - 1;

reg [SAMPLE_WIDTH-1:0] buffer [0:BUFFER_SIZE-1];
reg [$clog2(BUFFER_SIZE)-1:0] rd_ptr;
reg [$clog2(BUFFER_SIZE)-1:0] wr_ptr;
reg [$clog2(FRAME_SIZE)-1:0] frame_cnt;

always @(posedge clk) begin
    if (rst) begin
        rd_ptr <= 0;
        wr_ptr <= 0;
        frame_cnt <= 0;
        frame_valid <= 0;
    end else begin
        if (sample_valid) begin
            buffer[wr_ptr] <= audio_sample;
            wr_ptr <= (wr_ptr == BUFFER_SIZE-1) ? 0 : wr_ptr + 1;
        end

        if (wr_ptr - rd_ptr >= FRAME_SIZE || (wr_ptr < rd_ptr && BUFFER_SIZE - rd_ptr + wr_ptr >= FRAME_SIZE)) begin
            framed_audio <= buffer[rd_ptr];
            rd_ptr <= (rd_ptr == BUFFER_SIZE-1) ? 0 : rd_ptr + 1;
            frame_cnt <= (frame_cnt == FRAME_SIZE-1) ? 0 : frame_cnt + 1;
            frame_valid <= (frame_cnt == FRAME_SIZE-1);
        end else begin
            frame_valid <= 0;
        end
    end
end

endmodule