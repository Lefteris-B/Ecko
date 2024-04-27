module softmax #(
    parameter INPUT_SIZE = 10,
    parameter ACTIV_BITS = 8,
    parameter LUT_SIZE = 256,
    parameter LUT_ADDR_BITS = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE*ACTIV_BITS-1:0] input_data,
    input wire input_valid,
    output reg [INPUT_SIZE*ACTIV_BITS-1:0] output_data,
    output reg output_valid
);

    // Fixed-point representation parameters
    localparam FRAC_BITS = 8;
    localparam FIXED_ONE = 2**FRAC_BITS;

    // Exponential LUT
    reg [ACTIV_BITS-1:0] exp_lut [0:LUT_SIZE-1];

    // Registers for pipelining
    reg [INPUT_SIZE*ACTIV_BITS-1:0] input_data_reg;
    reg [INPUT_SIZE*ACTIV_BITS-1:0] exp_values;
    reg [ACTIV_BITS-1:0] sum_exp;
    reg [ACTIV_BITS-1:0] inv_sum_exp;

    // Generate exponential LUT
    integer i;
    initial begin
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            exp_lut[i] = $rtoi($exp(i / FIXED_ONE) * FIXED_ONE);
        end
    end

    // Pipeline stage 1: Register input data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_data_reg <= 0;
        end else begin
            input_data_reg <= input_data;
        end
    end

    // Pipeline stage 2: Calculate exponential values
    generate
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    exp_values[i*ACTIV_BITS +: ACTIV_BITS] <= 0;
                end else begin
                    exp_values[i*ACTIV_BITS +: ACTIV_BITS] <= exp_lut[input_data_reg[i*ACTIV_BITS +: LUT_ADDR_BITS]];
                end
            end
        end
    endgenerate

    // Pipeline stage 3: Sum up exponential values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_exp <= 0;
        end else begin
            sum_exp <= exp_values[0 +: ACTIV_BITS] + exp_values[ACTIV_BITS +: ACTIV_BITS] + ... + exp_values[(INPUT_SIZE-1)*ACTIV_BITS +: ACTIV_BITS];
        end
    end

    // Pipeline stage 4: Calculate inverse of sum
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inv_sum_exp <= 0;
        end else begin
            inv_sum_exp <= $rtoi(FIXED_ONE / sum_exp);
        end
    end

    // Pipeline stage 5: Divide exponential values by sum
    generate
        for (i = 0; i < INPUT_SIZE; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    output_data[i*ACTIV_BITS +: ACTIV_BITS] <= 0;
                end else begin
                    output_data[i*ACTIV_BITS +: ACTIV_BITS] <= $rtoi(exp_values[i*ACTIV_BITS +: ACTIV_BITS] * inv_sum_exp);
                end
            end
        end
    endgenerate

    // Output valid signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_valid <= 0;
        end else begin
            output_valid <= input_valid;
        end
    end

endmodule