module periodogram_squared (
  input wire clk,
  input wire rst,
  input wire signed [15:0] sample_in,
  input wire sample_valid,
  output reg [31:0] periodogram_out
  //utput reg periodogram_valid
);

  localparam NF = 512; // Power-of-two size for FFT
  localparam Q = 15; // Number of fractional bits

  reg signed [15:0] sample_buffer [0:NF-1];
  reg [$clog2(NF)-1:0] sample_count;
  reg [$clog2(NF)-1:0] fft_stage;
  reg [$clog2(NF)-1:0] fft_index;
  reg signed [15:0] fft_buffer [0:NF-1];
  reg signed [31:0] mult_real;
  reg signed [31:0] mult_imag;

  // Twiddle factor ROM
  reg signed [15:0] twiddle_real [0:NF/2-1];
  reg signed [15:0] twiddle_imag [0:NF/2-1];

  // Bit-reversed addressing lookup table
  reg [$clog2(NF)-1:0] bit_reversed [0:NF-1];

  // Initialize twiddle factor ROM and bit-reversed lookup table
  integer i;
  initial begin
    // Precompute twiddle factors and store in ROM
    twiddle_real[0] = 16'h7FFF; // cos(0) = 1
    twiddle_imag[0] = 16'h0000; // sin(0) = 0
    
    for (i = 1; i < NF/4; i = i + 1) begin
      // Approximate twiddle factors using synthesizable constants
      twiddle_real[i]         =  16'h7FFF - (16'h0324 * i); // cos(2*pi*i/NF)
      twiddle_imag[i]         = -16'h0648 * i;              // -sin(2*pi*i/NF)
      twiddle_real[NF/2-i]    = -twiddle_real[i];           // cos(pi-x) = -cos(x)
      twiddle_imag[NF/2-i]    =  twiddle_imag[i];           // sin(pi-x) = sin(x)
    end

    // Precompute bit-reversed addresses and store in lookup table
    for (i = 0; i < NF; i = i + 1) begin
      bit_reversed[i] = 0;
      for (integer j = 0; j < $clog2(NF); j = j + 1) begin
        bit_reversed[i][$clog2(NF)-1-j] = i[j];
      end
    end
  end

  // FFT butterflies
  always @(posedge clk) begin
    if (rst) begin
      sample_count <= 0;
      fft_stage <= 0;
      fft_index <= 0;
     // periodogram_valid <= 0;
    end else begin
      if (sample_valid) begin
        sample_buffer[sample_count] <= sample_in;
        sample_count <= sample_count + 1;

        if (sample_count == NF-1) begin
          // Start FFT
          fft_stage <= 0;
          fft_index <= 0;
          
          // Load samples into FFT buffer in bit-reversed order
          for (i = 0; i < NF; i = i + 1) begin
            fft_buffer[i] = sample_buffer[bit_reversed[i]];
          end
        end
      end

      if (fft_stage < $clog2(NF)) begin
        // Perform butterfly operation
        for (i = 0; i < NF/2; i = i + 1) begin
          if ((i & (1 << fft_stage)) == 0) begin
            mult_real <= (twiddle_real[i] * fft_buffer[i + (1 << fft_stage)]) >>> Q;
            mult_imag <= (twiddle_imag[i] * fft_buffer[i + (1 << fft_stage)]) >>> Q;

            fft_buffer[i + (1 << fft_stage)] = fft_buffer[i] - mult_real;
            fft_buffer[i] = fft_buffer[i] + mult_real;
          end
        end

        fft_stage <= fft_stage + 1;
      end else begin
        // Calculate squared magnitude
        periodogram_out <= (fft_buffer[fft_index] * fft_buffer[fft_index]) >>> Q;
        //periodogram_valid <= 1;
        fft_index <= fft_index + 1;

        if (fft_index == NF-1) begin
          //periodogram_valid <= 0;
        end
      end
    end
  end

endmodule
