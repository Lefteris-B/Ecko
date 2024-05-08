module pow_module #(
    parameter Q = 15 // Number of fractional bits in the input data
) (
    input wire clk,
    input wire rst,
    input wire signed [31:0] data_in,
    input wire data_valid,
    output reg signed [31:0] data_out,
    output reg data_out_valid
);

localparam POWER = 2; // Fixed power value (e.g., power of 2)

reg signed [31:0] data_reg;

always @(posedge clk) begin
    if (rst) begin
        data_reg <= 0;
        data_out <= 0;
        data_out_valid <= 0;
    end else begin
        if (data_valid) begin
            data_reg <= $signed(data_in) * $signed(data_in) >>> Q;
            data_out <= data_reg;
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end
end

endmodule
