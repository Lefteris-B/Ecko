// Goertzel Algorithm Module
module goertzel #(
    parameter DATA_WIDTH  = 16,
    parameter FREQ_WIDTH  = 16,
    parameter SAMPLE_RATE = 16000,
    parameter NUM_FREQS   = 10
)(
    input                              clk,
    input                              rst_n,
    input  signed [DATA_WIDTH-1:0]     sample_in,
    input                              sample_valid,
    input  [FREQ_WIDTH-1:0]            freq_values [0:NUM_FREQS-1],
    output signed [DATA_WIDTH+1:0]     mag_out [0:NUM_FREQS-1],
    output                             mag_valid
);

    // Fixed-point representation of coefficients
    localparam COEFF_WIDTH = 32;
    localparam COEFF_FRAC_BITS = 30;

    // Goertzel algorithm coefficients
    reg signed [COEFF_WIDTH-1:0] coeff [0:NUM_FREQS-1];

    // Goertzel algorithm state variables
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] q0 [0:NUM_FREQS-1];
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] q1 [0:NUM_FREQS-1];

    // Counter for samples
    reg [$clog2(SAMPLE_RATE)-1:0] sample_cnt;

    // Magnitude calculation
    reg signed [DATA_WIDTH+1:0] mag_reg [0:NUM_FREQS-1];

    // Compute Goertzel algorithm coefficients
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_FREQS; i = i + 1) begin
                coeff[i] <= 0;
            end
        end else begin
            for (i = 0; i < NUM_FREQS; i = i + 1) begin
                coeff[i] <= $rtoi(2 * $cos(2 * 3.14159 * freq_values[i] / SAMPLE_RATE) * (1 << COEFF_FRAC_BITS));
            end
        end
    end

    // Goertzel algorithm iteration
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < NUM_FREQS; j = j + 1) begin
                q0[j] <= 0;
                q1[j] <= 0;
            end
            sample_cnt <= 0;
        end else if (sample_valid) begin
            for (j = 0; j < NUM_FREQS; j = j + 1) begin
                q0[j] <= (sample_in << COEFF_FRAC_BITS) + ((coeff[j] * q0[j]) >>> COEFF_FRAC_BITS) - q1[j];
                q1[j] <= q0[j];
            end
            sample_cnt <= sample_cnt + 1;
        end
    end

    // Magnitude calculation
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < NUM_FREQS; k = k + 1) begin
                mag_reg[k] <= 0;
            end
        end else if (sample_cnt == SAMPLE_RATE - 1) begin
            for (k = 0; k < NUM_FREQS; k = k + 1) begin
                mag_reg[k] <= $sqrt(q0[k] * q0[k] + q1[k] * q1[k] - ((coeff[k] * q0[k]) >>> COEFF_FRAC_BITS) * q1[k]);
            end
        end
    end

    // Output magnitudes and valid signal
    assign mag_out = mag_reg;
    assign mag_valid = (sample_cnt == SAMPLE_RATE - 1);

endmodule