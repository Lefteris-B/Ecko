module maxpool2d #(
    parameter INPUT_WIDTH = 32,
    parameter INPUT_HEIGHT = 32,
    parameter INPUT_CHANNELS = 16,
    parameter POOL_SIZE = 2,
    parameter ACTIV_BITS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS-1:0] input_data,
    input wire input_valid,
    output reg [(INPUT_WIDTH/POOL_SIZE)*(INPUT_HEIGHT/POOL_SIZE)*INPUT_CHANNELS*ACTIV_BITS-1:0] output_data,
    output reg output_valid
);

    localparam OUTPUT_WIDTH = INPUT_WIDTH / POOL_SIZE;
    localparam OUTPUT_HEIGHT = INPUT_HEIGHT / POOL_SIZE;

    // Input buffer
    reg [INPUT_WIDTH-1:0] input_buffer [0:INPUT_HEIGHT-1][0:INPUT_CHANNELS-1];

    // Output buffer
    reg [ACTIV_BITS-1:0] output_buffer [0:OUTPUT_WIDTH-1][0:OUTPUT_HEIGHT-1][0:INPUT_CHANNELS-1];

    // Max pooling operation
    genvar i, j, k;
    generate
        for (i = 0; i < OUTPUT_WIDTH; i = i + 1) begin
            for (j = 0; j < OUTPUT_HEIGHT; j = j + 1) begin
                for (k = 0; k < INPUT_CHANNELS; k = k + 1) begin
                    wire [ACTIV_BITS-1:0] max_val;
                    max_pool_window #(
                        .POOL_SIZE(POOL_SIZE),
                        .ACTIV_BITS(ACTIV_BITS)
                    ) pool_window (
                        .window_data(input_buffer[i*POOL_SIZE +: POOL_SIZE][j*POOL_SIZE +: POOL_SIZE][k]),
                        .max_val(max_val)
                    );
                    always @(posedge clk or negedge rst_n) begin
                        if (!rst_n) begin
                            output_buffer[i][j][k] <= 0;
                        end else begin
                            output_buffer[i][j][k] <= max_val;
                        end
                    end
                end
            end
        end
    endgenerate

    // Input buffering and reshaping
    integer m, n, p;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (m = 0; m < INPUT_HEIGHT; m = m + 1) begin
                for (n = 0; n < INPUT_CHANNELS; n = n + 1) begin
                    input_buffer[m][n] <= 0;
                end
            end
        end else begin
            if (input_valid) begin
                for (m = 0; m < INPUT_HEIGHT; m = m + 1) begin
                    for (n = 0; n < INPUT_CHANNELS; n = n + 1) begin
                        input_buffer[m][n] <= input_data[(m*INPUT_CHANNELS+n)*INPUT_WIDTH +: INPUT_WIDTH];
                    end
                end
            end
        end
    end

    // Output flattening and valid signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_data <= 0;
            output_valid <= 0;
        end else begin
            output_valid <= input_valid;
            for (m = 0; m < OUTPUT_WIDTH; m = m + 1) begin
                for (n = 0; n < OUTPUT_HEIGHT; n = n + 1) begin
                    for (p = 0; p < INPUT_CHANNELS; p = p + 1) begin
                        output_data[((m*OUTPUT_HEIGHT+n)*INPUT_CHANNELS+p)*ACTIV_BITS +: ACTIV_BITS] <= output_buffer[m][n][p];
                    end
                end
            end
        end
    end

endmodule

// Max pooling window submodule
module max_pool_window #(
    parameter POOL_SIZE = 2,
    parameter ACTIV_BITS = 8
)(
    input wire [POOL_SIZE*POOL_SIZE*ACTIV_BITS-1:0] window_data,
    output wire [ACTIV_BITS-1:0] max_val
);

    // Comparator tree to find the maximum value
    genvar i, j;
    wire [ACTIV_BITS-1:0] max_val_level [0:$clog2(POOL_SIZE*POOL_SIZE)-1];

    generate
        for (i = 0; i < POOL_SIZE*POOL_SIZE; i = i + 2) begin
            assign max_val_level[0][i/2] = (window_data[i*ACTIV_BITS +: ACTIV_BITS] > window_data[(i+1)*ACTIV_BITS +: ACTIV_BITS]) ?
                                            window_data[i*ACTIV_BITS +: ACTIV_BITS] : window_data[(i+1)*ACTIV_BITS +: ACTIV_BITS];
        end

        for (i = 1; i < $clog2(POOL_SIZE*POOL_SIZE); i = i + 1) begin
            for (j = 0; j < (POOL_SIZE*POOL_SIZE)/(2**i); j = j + 2) begin
                assign max_val_level[i][j/2] = (max_val_level[i-1][j] > max_val_level[i-1][j+1]) ?
                                                max_val_level[i-1][j] : max_val_level[i-1][j+1];
            end
        end
    endgenerate

    assign max_val = max_val_level[$clog2(POOL_SIZE*POOL_SIZE)-1][0];

endmodule