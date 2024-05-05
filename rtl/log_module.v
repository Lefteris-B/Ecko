module log_module #(
  parameter Q_M = 15,  // Number of fractional bits for Mel filter coefficients
  parameter Q_L = 11   // Number of fractional bits for logarithm output
) (
  input wire clk,
  input wire rst,
  input wire signed [31:0] data_in,
  input wire data_valid,
  output reg signed [Q_L-1:0] log_out,
  output reg log_valid
);

  localparam INT_BITS = 32 - Q_M;
  localparam FRAC_BITS = Q_M;

  reg signed [INT_BITS-1:0] int_part;
  reg signed [FRAC_BITS-1:0] frac_part;
  reg signed [FRAC_BITS-1:0] frac_part_shifted;
  reg [$clog2(FRAC_BITS)-1:0] shift_count;
  reg [1:0] state;

  always @(posedge clk) begin
    if (rst) begin
      int_part <= 0;
      frac_part <= 0;
      frac_part_shifted <= 0;
      shift_count <= 0;
      log_out <= 0;
      log_valid <= 0;
      state <= 0;
    end else begin
      case (state)
        0: begin
          if (data_valid) begin
            int_part <= data_in[31:FRAC_BITS];
            frac_part <= data_in[FRAC_BITS-1:0];
            state <= 1;
          end
        end

        1: begin
          if (int_part > 0) begin
            int_part <= int_part >> 1;
            frac_part_shifted <= frac_part;
            shift_count <= 0;
            state <= 2;
          end else begin
            log_out <= frac_part >> (FRAC_BITS - Q_L);
            log_valid <= 1;
            state <= 0;
          end
        end

        2: begin
          if (shift_count < FRAC_BITS) begin
            if (frac_part_shifted >= (1 << (FRAC_BITS - 1))) begin
              frac_part_shifted <= (frac_part_shifted << 1) - (1 << FRAC_BITS);
              log_out <= (log_out << 1) + 1;
            end else begin
              frac_part_shifted <= frac_part_shifted << 1;
              log_out <= log_out << 1;
            end
            shift_count <= shift_count + 1;
          end else begin
            log_out <= log_out + (int_part << (Q_L - $clog2(INT_BITS)));
            log_valid <= 1;
            state <= 0;
          end
        end
      endcase
    end
  end

endmodule