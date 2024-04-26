module framing_windowing (
    input wire clk,
    input wire rst_n,
    input wire [15:0] preemph_out,
    input wire preemph_valid,
    input wire [7:0] frame_size,
    input wire [7:0] frame_overlap,
    output reg [15:0] framed_out,
    output reg framed_valid
);

// Hamming window coefficients
reg [15:0] hamming_window [0:255];

// Frame buffer
reg [15:0] frame_buffer [0:255];
reg [7:0] frame_counter;
reg frame_buffer_full;

// Constants for Hamming window calculation
localparam integer Q15_ONE = 16'h7FFF;
localparam integer Q15_HALF = 16'h4000;
localparam integer TWOPI_Q15 = 16'h6487;

// Calculate Hamming window coefficients
function [15:0] hamming_coeff(input [7:0] n, input [7:0] N);
    reg [31:0] temp;
    reg [15:0] cosine;
    integer i;
    
    // Cosine lookup table (pre-computed values for 256 points)
    reg [15:0] cos_table [0:255] = {
    16'h0A3D, 16'h0A42, 16'h0A50, 16'h0A67, 16'h0A87, 16'h0AB0, 16'h0AE2, 16'h0B1D,
    16'h0B61, 16'h0BAF, 16'h0C05, 16'h0C64, 16'h0CCC, 16'h0D3C, 16'h0DB5, 16'h0E37,
    16'h0EC2, 16'h0F55, 16'h0FF0, 16'h1093, 16'h113F, 16'h11F3, 16'h12AE, 16'h1372,
    16'h143D, 16'h1510, 16'h15EA, 16'h16CC, 16'h17B5, 16'h18A5, 16'h199B, 16'h1A99,
    16'h1B9D, 16'h1CA8, 16'h1DB9, 16'h1ED0, 16'h1FED, 16'h2110, 16'h2238, 16'h2366,
    16'h2499, 16'h25D1, 16'h270E, 16'h284F, 16'h2996, 16'h2AE0, 16'h2C2E, 16'h2D81,
    16'h2ED7, 16'h3030, 16'h318D, 16'h32ED, 16'h344F, 16'h35B5, 16'h371C, 16'h3886,
    16'h39F2, 16'h3B5F, 16'h3CCE, 16'h3E3F, 16'h3FB0, 16'h4122, 16'h4295, 16'h4408,
    16'h457C, 16'h46EF, 16'h4862, 16'h49D4, 16'h4B46, 16'h4CB7, 16'h4E27, 16'h4F95,
    16'h5102, 16'h526D, 16'h53D5, 16'h553C, 16'h56A0, 16'h5801, 16'h595F, 16'h5ABA,
    16'h5C12, 16'h5D66, 16'h5EB7, 16'h6003, 16'h614B, 16'h628F, 16'h63CF, 16'h6509,
    16'h663F, 16'h676F, 16'h689A, 16'h69C0, 16'h6AE0, 16'h6BFA, 16'h6D0E, 16'h6E1C,
    16'h6F23, 16'h7024, 16'h711E, 16'h7212, 16'h72FE, 16'h73E3, 16'h74C1, 16'h7598,
    16'h7667, 16'h772E, 16'h77EE, 16'h78A6, 16'h7955, 16'h79FD, 16'h7A9C, 16'h7B33,
    16'h7BC2, 16'h7C48, 16'h7CC6, 16'h7D3B, 16'h7DA7, 16'h7E0A, 16'h7E65, 16'h7EB7,
    16'h7EFF, 16'h7F3F, 16'h7F76, 16'h7FA3, 16'h7FC8, 16'h7FE3, 16'h7FF6, 16'h7FFF,
    16'h7FFF, 16'h7FF6, 16'h7FE3, 16'h7FC8, 16'h7FA3, 16'h7F76, 16'h7F3F, 16'h7EFF,
    16'h7EB7, 16'h7E65, 16'h7E0A, 16'h7DA7, 16'h7D3B, 16'h7CC6, 16'h7C48, 16'h7BC2,
    16'h7B33, 16'h7A9C, 16'h79FD, 16'h7955, 16'h78A6, 16'h77EE, 16'h772E, 16'h7667,
    16'h7598, 16'h74C1, 16'h73E3, 16'h72FE, 16'h7212, 16'h711E, 16'h7024, 16'h6F23,
    16'h6E1C, 16'h6D0E, 16'h6BFA, 16'h6AE0, 16'h69C0, 16'h689A, 16'h676F, 16'h663F,
    16'h6509, 16'h63CF, 16'h628F, 16'h614B, 16'h6003, 16'h5EB7, 16'h5D66, 16'h5C12,
    16'h5ABA, 16'h595F, 16'h5801, 16'h56A0, 16'h553C, 16'h53D5, 16'h526D, 16'h5102,
    16'h4F95, 16'h4E27, 16'h4CB7, 16'h4B46, 16'h49D4, 16'h4862, 16'h46EF, 16'h457C,
    16'h4408, 16'h4295, 16'h4122, 16'h3FB0, 16'h3E3F, 16'h3CCE, 16'h3B5F, 16'h39F2,
    16'h3886, 16'h371C, 16'h35B5, 16'h344F, 16'h32ED, 16'h318D, 16'h3030, 16'h2ED7,
    16'h2D81, 16'h2C2E, 16'h2AE0, 16'h2996, 16'h284F, 16'h270E, 16'h25D1, 16'h2499,
    16'h2366, 16'h2238, 16'h2110, 16'h1FED, 16'h1ED0, 16'h1DB9, 16'h1CA8, 16'h1B9D,
    16'h1A99, 16'h199B, 16'h18A5, 16'h17B5, 16'h16CC, 16'h15EA, 16'h1510, 16'h143D,
    16'h1372, 16'h12AE, 16'h11F3, 16'h113F, 16'h1093, 16'h0FF0, 16'h0F55, 16'h0EC2,
    16'h0E37, 16'h0DB5, 16'h0D3C, 16'h0CCC, 16'h0C64, 16'h0C05, 16'h0BAF, 16'h0B61,
    16'h0B1D, 16'h0AE2, 16'h0AB0, 16'h0A87, 16'h0A67, 16'h0A50, 16'h0A42, 16'h0A3D
};
    
    // Calculate the cosine index based on n and N
    i = (n * 256) / (N - 1);
    
    // Look up the cosine value from the pre-computed table
    cosine = cos_table[i];
    
    // Calculate the Hamming window coefficient
    temp = (Q15_ONE - ((Q15_HALF * cosine) >>> 15)) >>> 1;
    return temp[15:0];
endfunction

// Initialize Hamming window coefficients
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 256; i = i + 1) begin
            hamming_window[i] <= hamming_coeff(i, frame_size);
        end
    end
end

// Framing and windowing logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        frame_counter <= 8'h00;
        frame_buffer_full <= 1'b0;
        framed_out <= 16'h0000;
        framed_valid <= 1'b0;
    end else if (preemph_valid) begin
        // Store pre-emphasized samples in frame buffer
        frame_buffer[frame_counter] <= preemph_out;
        frame_counter <= frame_counter + 1;

        // Check if frame buffer is full
        if (frame_counter == frame_size - 1) begin
            frame_buffer_full <= 1'b1;
            frame_counter <= frame_size - frame_overlap - 1;
        end

        // Apply Hamming window and output framed samples
        if (frame_buffer_full) begin
            framed_out <= (frame_buffer[frame_counter] * hamming_window[frame_counter]) >>> 15;
            framed_valid <= 1'b1;
        end else begin
            framed_valid <= 1'b0;
        end
    end else begin
        framed_valid <= 1'b0;
    end
end

endmodule