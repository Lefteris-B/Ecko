// Logarithm Module
module logarithm #(
    parameter DATA_WIDTH  = 16,
    parameter LOG_WIDTH   = 8,
    parameter NUM_FILTERS = 26
)(
    input                                  clk,
    input                                  rst_n,
    input  signed [DATA_WIDTH-1:0]         mel_in [0:NUM_FILTERS-1],
    input                                  mel_valid,
    output signed [LOG_WIDTH-1:0]          log_out [0:NUM_FILTERS-1],
    output                                 log_valid
);

    // Logarithm computation parameters
    localparam int LOG_TABLE_SIZE = 256;
    localparam int LOG_TABLE_WIDTH = 10;
    localparam int LOG_TABLE_FRAC_BITS = 8;

    // Logarithm lookup table
    logic signed [LOG_TABLE_WIDTH-1:0] log_table [0:LOG_TABLE_SIZE-1];

    // Initialize logarithm lookup table
    initial begin
        for (int i = 0; i < LOG_TABLE_SIZE; i++) begin
            log_table[i] = $rtoi($ln(i + 1) * (1 << LOG_TABLE_FRAC_BITS));
        end
    end

    // Logarithm computation
    genvar i;
    generate
        for (i = 0; i < NUM_FILTERS; i++) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    log_out[i] <= 0;
                end else if (mel_valid) begin
                    if (mel_in[i] <= 0) begin
                        log_out[i] <= -(1 << (LOG_WIDTH-1));  // Minimum value
                    end else if (mel_in[i] >= LOG_TABLE_SIZE) begin
                        log_out[i] <= log_table[LOG_TABLE_SIZE-1] >>> (LOG_TABLE_FRAC_BITS - (LOG_WIDTH-1));  // Maximum value
                    end else begin
                        log_out[i] <= log_table[mel_in[i]] >>> (LOG_TABLE_FRAC_BITS - (LOG_WIDTH-1));  // Quantized logarithm value
                    end
                end
            end
        end
    endgenerate

    // Output valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            log_valid <= 0;
        end else begin
            log_valid <= mel_valid;
        end
    end

endmodule