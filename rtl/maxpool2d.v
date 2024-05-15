module maxpool2d #(
    parameter INPUT_WIDTH = 40,
    parameter INPUT_HEIGHT = 1,
    parameter INPUT_CHANNELS = 8,
    parameter KERNEL_SIZE = 2,
    parameter STRIDE = 2,
    parameter ACTIV_BITS = 16
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH * INPUT_HEIGHT * INPUT_CHANNELS * ACTIV_BITS-1:0] data_in,
    input wire data_valid,
    output reg [(INPUT_WIDTH/STRIDE) * INPUT_CHANNELS * ACTIV_BITS-1:0] data_out,
    output reg data_out_valid
);

    localparam OUTPUT_WIDTH = INPUT_WIDTH / STRIDE;
    localparam OUTPUT_HEIGHT = INPUT_HEIGHT / STRIDE;

    // Declare internal signals
    reg [ACTIV_BITS-1:0] input_buffer [0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1][0:INPUT_CHANNELS-1];
    reg [ACTIV_BITS-1:0] max_value [0:INPUT_CHANNELS-1];

    // Max pooling operation
    integer i, j, k, m, n;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal signals and output
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                    for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                        input_buffer[i][j][k] <= 0;
                    end
                end
            end
            data_out <= 0;
            data_out_valid <= 0;
        end else if (data_valid) begin
            // Shift input data into buffer
            for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                    for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                        if (j < INPUT_WIDTH - 1) begin
                            input_buffer[i][j][k] <= input_buffer[i][j+1][k];
                        end else begin
                            input_buffer[i][j][k] <= data_in[i*INPUT_WIDTH*INPUT_CHANNELS*ACTIV_BITS + j*INPUT_CHANNELS*ACTIV_BITS + k*ACTIV_BITS +: ACTIV_BITS];
                        end
                    end
                end
            end

            // Perform max pooling
            for (i = 0; i < OUTPUT_HEIGHT; i = i + 1) begin
                for (j = 0; j < OUTPUT_WIDTH; j = j + 1) begin
                    for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                        max_value[k] = input_buffer[i*STRIDE][j*STRIDE][k];
                        for (m = 0; m < KERNEL_SIZE; m = m + 1) begin
                            for (n = 0; n < KERNEL_SIZE; n = n + 1) begin
                                if (i*STRIDE + m < INPUT_HEIGHT && j*STRIDE + n < INPUT_WIDTH) begin
                                    max_value[k] = (input_buffer[i*STRIDE + m][j*STRIDE + n][k] > max_value[k]) ? input_buffer[i*STRIDE + m][j*STRIDE + n][k] : max_value[k];
                                end
                            end
                        end
                        data_out[i*OUTPUT_WIDTH*INPUT_CHANNELS*ACTIV_BITS + j*INPUT_CHANNELS*ACTIV_BITS + k*ACTIV_BITS +: ACTIV_BITS] <= max_value[k];
                    end
                end
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

endmodule

