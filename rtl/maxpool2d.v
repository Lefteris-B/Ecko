module maxpool2d #(
    parameter INPUT_WIDTH = 16,
    parameter INPUT_HEIGHT = 1,
    parameter INPUT_CHANNELS = 32,
    parameter KERNEL_WIDTH = 2,
    parameter KERNEL_HEIGHT = 1,
    parameter STRIDE = 2
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS-1:0] data_in,
    input wire data_valid,
    output reg [(INPUT_WIDTH/STRIDE)*(INPUT_HEIGHT/STRIDE)*INPUT_CHANNELS-1:0] data_out,
    output reg data_out_valid
);

// Declare internal signals
reg [INPUT_WIDTH-1:0] input_buffer [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];
reg [INPUT_WIDTH-1:0] max_value;

// Max pooling operation
integer i, j, k, m, n;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset internal signals and output
        for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
            for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                input_buffer[i][j] <= 0;
            end
        end
        data_out <= 0;
        data_out_valid <= 0;
    end else begin
        // Shift input data into buffer
        if (data_valid) begin
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH - 1; j = j + 1) begin
                    input_buffer[i][j] <= input_buffer[i][j + 1];
                end
                input_buffer[i][INPUT_WIDTH - 1] <= data_in[i*INPUT_WIDTH +: INPUT_WIDTH];
            end
        end

        // Perform max pooling
        for (i = 0; i < INPUT_HEIGHT; i = i + STRIDE) begin
            for (j = 0; j < INPUT_WIDTH; j = j + STRIDE) begin
                for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                    max_value <= input_buffer[i][j];
                    for (m = 0; m < KERNEL_HEIGHT; m = m + 1) begin
                        for (n = 0; n < KERNEL_WIDTH; n = n + 1) begin
                            if (i + m < INPUT_HEIGHT && j + n < INPUT_WIDTH) begin
                                max_value <= (input_buffer[i + m][j + n] > max_value) ? input_buffer[i + m][j + n] : max_value;
                            end
                        end
                    end
                    data_out[((i/STRIDE)*(INPUT_WIDTH/STRIDE) + (j/STRIDE))*INPUT_CHANNELS + k] <= max_value;
                end
            end
        end
        data_out_valid <= 1;
    end
end

endmodule
