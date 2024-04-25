// DCT Module
module dct #(
    parameter DATA_WIDTH  = 16,
    parameter NUM_MFCC    = 13,
    parameter NUM_FILTERS = 26
)(
    input                                         clk,
    input                                         rst_n,
    input  signed [DATA_WIDTH-1:0]                log_in [0:NUM_FILTERS-1],
    input                                         log_valid,
    output signed [DATA_WIDTH-1:0]                mfcc_out [0:NUM_MFCC-1],
    output                                        mfcc_valid
);

    // Fixed-point representation parameters
    localparam COEFF_WIDTH = 16;
    localparam COEFF_FRAC_BITS = 14;
    localparam SCALE_FACTOR = 2 ** (COEFF_FRAC_BITS - 1);

    // DCT-II coefficients
    reg signed [COEFF_WIDTH-1:0] dct_coeff [0:NUM_MFCC-1][0:NUM_FILTERS-1];

    // Intermediate registers
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] dct_sum [0:NUM_MFCC-1];
    reg signed [DATA_WIDTH-1:0] mfcc_reg [0:NUM_MFCC-1];

    // Generate DCT-II coefficients
    integer i, j;
    real coeff_real;
    initial begin
        for (i = 0; i < NUM_MFCC; i = i + 1) begin
            for (j = 0; j < NUM_FILTERS; j = j + 1) begin
                coeff_real = $sqrt(2.0 / NUM_FILTERS) * $cos(3.14159 * (j + 0.5) * i / NUM_FILTERS);
                dct_coeff[i][j] = $rtoi(coeff_real * SCALE_FACTOR);
            end
        end
    end

    // DCT-II computation
    integer k, m;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < NUM_MFCC; k = k + 1) begin
                dct_sum[k] <= 0;
                mfcc_reg[k] <= 0;
            end
        end else if (log_valid) begin
            for (k = 0; k < NUM_MFCC; k = k + 1) begin
                dct_sum[k] <= 0;
                for (m = 0; m < NUM_FILTERS; m = m + 1) begin
                    dct_sum[k] <= dct_sum[k] + log_in[m] * dct_coeff[k][m];
                end
                // Scaling and rounding
                mfcc_reg[k] <= dct_sum[k] >>> COEFF_FRAC_BITS;
            end
        end
    end

    // Output MFCC features and valid signal
    assign mfcc_out = mfcc_reg;
    assign mfcc_valid = log_valid;

endmodule