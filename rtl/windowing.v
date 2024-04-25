// Windowing Module
module windowing #(
    parameter DATA_WIDTH  = 16,
    parameter FRAME_SIZE  = 256,
    parameter WINDOW_TYPE = "hamming"
)(
    input                            clk,
    input                            rst_n,
    input  [DATA_WIDTH-1:0]          frame_data [0:FRAME_SIZE-1],
    input                            frame_valid,
    output [DATA_WIDTH-1:0]          windowed_data [0:FRAME_SIZE-1],
    output                           windowed_valid
);

    // Fixed-point representation of window coefficients
    localparam COEFF_WIDTH = 16;
    localparam COEFF_FRAC_BITS = 15;

    // Generate window coefficients
    wire [COEFF_WIDTH-1:0] window_coeff [0:FRAME_SIZE-1];

    generate
        if (WINDOW_TYPE == "hamming") begin
            // Hamming window coefficients
            for (genvar i = 0; i < FRAME_SIZE; i++) begin
                localparam real coeff = 0.54 - 0.46 * $cos(2 * 3.14159 * i / (FRAME_SIZE - 1));
                assign window_coeff[i] = $rtoi(coeff * (1 << COEFF_FRAC_BITS));
            end
        end else if (WINDOW_TYPE == "hann") begin
            // Hann window coefficients
            for (genvar i = 0; i < FRAME_SIZE; i++) begin
                localparam real coeff = 0.5 * (1 - $cos(2 * 3.14159 * i / (FRAME_SIZE - 1)));
                assign window_coeff[i] = $rtoi(coeff * (1 << COEFF_FRAC_BITS));
            end
        end else if (WINDOW_TYPE == "blackman") begin
            // Blackman window coefficients
            for (genvar i = 0; i < FRAME_SIZE; i++) begin
                localparam real coeff = 0.42 - 0.5 * $cos(2 * 3.14159 * i / (FRAME_SIZE - 1)) + 0.08 * $cos(4 * 3.14159 * i / (FRAME_SIZE - 1));
                assign window_coeff[i] = $rtoi(coeff * (1 << COEFF_FRAC_BITS));
            end
        end else begin
            // Rectangular window (default)
            for (genvar i = 0; i < FRAME_SIZE; i++) begin
                assign window_coeff[i] = 1 << COEFF_FRAC_BITS;
            end
        end
    endgenerate

    // Apply window function to frame data
    genvar i;
    generate
        for (i = 0; i < FRAME_SIZE; i++) begin
            always @(posedge clk) begin
                if (frame_valid) begin
                    windowed_data[i] <= (frame_data[i] * window_coeff[i]) >>> COEFF_FRAC_BITS;
                end
            end
        end
    endgenerate

    // Assert windowed_valid signal
    reg windowed_valid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            windowed_valid_reg <= 0;
        end else begin
            windowed_valid_reg <= frame_valid;
        end
    end
    assign windowed_valid = windowed_valid_reg;

endmodule