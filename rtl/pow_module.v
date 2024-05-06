module pow_module #(
  parameter Q = 15  // Number of fractional bits in the input data
) (
  input wire clk,
  input wire rst,
  input wire signed [15:0] data_in,
  input wire data_valid,
  output reg signed [31:0] data_out
  //output reg data_out_valid
);

  localparam POWER = 2;  // Fixed power value (e.g., power of 2)

  reg signed [15:0] data_reg;
  reg [3:0] state;
  reg [3:0] counter;

  always @(posedge clk) begin
    if (rst) begin
      data_reg <= 0;
      data_out <= 0;
      //data_out_valid <= 0;
      state <= 0;
      counter <= 0;
    end else begin
      case (state)
        0: begin
          if (data_valid) begin
            data_reg <= data_in;
            state <= 1;
            counter <= 0;
          end
        end

        1: begin
          if (counter < POWER - 1) begin
            data_reg <= (data_reg * data_reg) >>> Q;
            counter <= counter + 1;
          end else begin
            data_out <= (data_reg * data_reg) >>> Q;
           // data_out_valid <= 1;
            state <= 2;
          end
        end

        2: begin
         // data_out_valid <= 0;
          state <= 0;
        end
      endcase
    end
  end

endmodule
