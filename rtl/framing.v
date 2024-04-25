// Framing Module
module framing #(
    parameter DATA_WIDTH   = 16,
    parameter FRAME_SIZE   = 256,
    parameter FRAME_STRIDE = 128
)(
    input                              clk,
    input                              rst_n,
    input  [DATA_WIDTH-1:0]            audio_in,
    input                              audio_valid,
    output [DATA_WIDTH-1:0]            frame_data [0:FRAME_SIZE-1],
    output                             frame_valid
);

    // Circular buffer signals
    reg [DATA_WIDTH-1:0] buffer [0:FRAME_SIZE-1];
    reg [$clog2(FRAME_SIZE):0] write_ptr;
    reg [$clog2(FRAME_SIZE):0] read_ptr;
    reg [$clog2(FRAME_SIZE):0] sample_cnt;

    // Update circular buffer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_ptr <= 0;
            sample_cnt <= 0;
        end else if (audio_valid) begin
            buffer[write_ptr] <= audio_in;
            write_ptr <= (write_ptr == FRAME_SIZE-1) ? 0 : write_ptr + 1;
            sample_cnt <= (sample_cnt == FRAME_SIZE-1) ? 0 : sample_cnt + 1;
        end
    end

    // Output frame data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_ptr <= 0;
        end else if (sample_cnt == FRAME_SIZE-1) begin
            read_ptr <= (read_ptr + FRAME_STRIDE >= FRAME_SIZE) ? read_ptr + FRAME_STRIDE - FRAME_SIZE : read_ptr + FRAME_STRIDE;
        end
    end

    // Assign output frame data
    genvar i;
    generate
        for (i = 0; i < FRAME_SIZE; i = i + 1) begin
            assign frame_data[i] = buffer[(read_ptr + i) % FRAME_SIZE];
        end
    endgenerate

    // Assert frame_valid signal
    assign frame_valid = (sample_cnt == FRAME_SIZE-1);

endmodule