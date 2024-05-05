module mel_filterbank #(
  parameter Q = 15,             // Number of fractional bits in the input data
  parameter NUM_FILTERS = 40,   // Number of Mel filters
  parameter FILTER_SIZE = 23,   // Size of each Mel filter
  parameter Q_M = 15            // Number of fractional bits for Mel filter coefficients
) (
  input wire clk,
  input wire rst,
  input wire signed [31:0] data_in,
  input wire data_valid,
  output reg signed [31:0] mel_out,
  output reg mel_valid
);

  localparam NUM_COEFFS = NUM_FILTERS * FILTER_SIZE;
  localparam COEFF_WIDTH = 16;

  reg signed [31:0] periodogram [0:FILTER_SIZE-1];
  reg [$clog2(NUM_FILTERS)-1:0] filter_counter;
  reg [$clog2(FILTER_SIZE)-1:0] coeff_counter;
  reg signed [COEFF_WIDTH-1:0] coeff;
  reg signed [47:0] accumulator;
  reg [1:0] state;

  // Mel filter coefficients
  function signed [COEFF_WIDTH-1:0] mel_coeff;
    input [$clog2(NUM_FILTERS)-1:0] filter_idx;
    input [$clog2(FILTER_SIZE)-1:0] coeff_idx;
    // Implement the Mel filter coefficient calculation here
    // based on the filter index and coefficient index
    // Return the calculated coefficient value
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      filter_counter <= 0;
      coeff_counter <= 0;
      accumulator <= 0;
      mel_out <= 0;
      mel_valid <= 0;
      state <= 0;
    end else begin
      case (state)
        0: begin
          if (data_valid) begin
            periodogram[filter_counter] <= data_in;
            filter_counter <= filter_counter + 1;
            if (filter_counter == FILTER_SIZE - 1) begin
              filter_counter <= 0;
              state <= 1;
            end
          end
        end

        1: begin
          coeff <= mel_coeff(filter_counter, coeff_counter);
          accumulator <= accumulator + $signed(periodogram[coeff_counter] * coeff);
          coeff_counter <= coeff_counter + 1;

          if (coeff_counter == FILTER_SIZE - 1) begin
            mel_out <= accumulator >>> (Q + Q_M);
            mel_valid <= 1;
            accumulator <= 0;
            coeff_counter <= 0;
            filter_counter <= filter_counter + 1;

            if (filter_counter == NUM_FILTERS) begin
              filter_counter <= 0;
              state <= 0;
            end
          end
        end
      endcase
    end
  end

endmodule