module hamming_window (
  input wire clk,
  input wire rst,
  input wire [15:0] sample_in,
  input wire sample_valid,
  output reg [15:0] sample_out,
  output reg sample_out_valid
);

  localparam N = 256; // Frame size
  localparam Q = 15; // Fixed-point precision
  localparam NF = 512; // Power-of-two size for zero-padding

  reg [15:0] sample_buffer [0:N-1];
  reg [$clog2(NF)-1:0] sample_count;
  reg [$clog2(N)-1:0] coeff_count;
  reg [15:0] coeff;

  // Fixed-point constants
  localparam [15:0] CONST_054 = 16'h4666; // 0.54 in Q15
  localparam [15:0] CONST_046 = 16'h3999; // 0.46 in Q15
  localparam [15:0] CONST_2PI = 16'h6487; // 2π in Q15

  // CORDIC approximation of cosine
  function [15:0] cordic_cos;
    input [15:0] angle;
    reg [15:0] x, y, z;
    reg [3:0] i;
    begin
      x = 16'h4DBA; // 0.607252935 in Q15
      y = 0;
      z = angle;

      for (i = 0; i < 12; i = i + 1) begin
        if (z[15] == 1) begin
          x = x - (y >>> i);
          y = y + (x >>> i);
          z = z + cordic_atan_table[i];
        end else begin
          x = x + (y >>> i);
          y = y - (x >>> i);
          z = z - cordic_atan_table[i];
        end
      end

      cordic_cos = x;
    end
  endfunction

  // CORDIC arctangent table (Q15)
  localparam [0:11] cordic_atan_table = {
    16'h3243, 16'h1DAC, 16'h0FAD, 16'h07F5,
    16'h03FE, 16'h01FF, 16'h0100, 16'h0080,
    16'h0040, 16'h0020, 16'h0010, 16'h0008
  };

 always @(posedge clk) begin
    if (rst) begin
      sample_count <= 0;
      coeff_count <= 0;
      sample_out <= 0;
      sample_out_valid <= 0;
    end else begin
      if (sample_valid) begin
        sample_buffer[sample_count] <= sample_in;
        sample_count <= (sample_count == N-1) ? 0 : sample_count + 1;

        if (sample_count == N-1) begin
          coeff_count <= 0;
          sample_out_valid <= 1;
        end else if (coeff_count < N) begin
          coeff <= CONST_054 - ((CONST_046 * cordic_cos((CONST_2PI * coeff_count) / (N-1))) >>> Q);
          sample_out <= (sample_buffer[coeff_count] * coeff) >>> Q;
          coeff_count <= coeff_count + 1;
        end else if (coeff_count < NF) begin
          sample_out <= 0; // Zero-padding
          coeff_count <= coeff_count + 1;
        end else begin
          sample_out_valid <= 0;
        end
      end
    end
  end

endmodule