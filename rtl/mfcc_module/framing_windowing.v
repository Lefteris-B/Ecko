`ifndef FRAMING_WINDOWING_V
`define FRAMING_WINDOWING_V

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
localparam integer Q15_ONE = 32'h7FFF;
localparam integer Q15_HALF = 32'h4000;

// Cosine lookup table (pre-computed values for 256 points)
reg [15:0] cos_table [0:255];

// Initialize the cosine lookup table
initial begin
    cos_table[0] = 16'h7FFF;
    cos_table[1] = 16'h7FF5;
    cos_table[2] = 16'h7FD8;
    cos_table[3] = 16'h7FA6;
    cos_table[4] = 16'h7F61;
    cos_table[5] = 16'h7F09;
    cos_table[6] = 16'h7E9C;
    cos_table[7] = 16'h7E1D;
    cos_table[8] = 16'h7D89;
    cos_table[9] = 16'h7CE3;
    cos_table[10] = 16'h7C29;
    cos_table[11] = 16'h7B5C;
    cos_table[12] = 16'h7A7C;
    cos_table[13] = 16'h7989;
    cos_table[14] = 16'h7884;
    cos_table[15] = 16'h776B;
    cos_table[16] = 16'h7641;
    cos_table[17] = 16'h7504;
    cos_table[18] = 16'h73B5;
    cos_table[19] = 16'h7254;
    cos_table[20] = 16'h70E2;
    cos_table[21] = 16'h6F5E;
    cos_table[22] = 16'h6DC9;
    cos_table[23] = 16'h6C23;
    cos_table[24] = 16'h6A6D;
    cos_table[25] = 16'h68A6;
    cos_table[26] = 16'h66CF;
    cos_table[27] = 16'h64E8;
    cos_table[28] = 16'h62F1;
    cos_table[29] = 16'h60EB;
    cos_table[30] = 16'h5ED7;
    cos_table[31] = 16'h5CB3;
    cos_table[32] = 16'h5A82;
    cos_table[33] = 16'h5842;
    cos_table[34] = 16'h55F5;
    cos_table[35] = 16'h539B;
    cos_table[36] = 16'h5133;
    cos_table[37] = 16'h4EBF;
    cos_table[38] = 16'h4C3F;
    cos_table[39] = 16'h49B4;
    cos_table[40] = 16'h471C;
    cos_table[41] = 16'h447A;
    cos_table[42] = 16'h41CE;
    cos_table[43] = 16'h3F17;
    cos_table[44] = 16'h3C56;
    cos_table[45] = 16'h398C;
    cos_table[46] = 16'h36BA;
    cos_table[47] = 16'h33DF;
    cos_table[48] = 16'h30FB;
    cos_table[49] = 16'h2E11;
    cos_table[50] = 16'h2B1F;
    cos_table[51] = 16'h2826;
    cos_table[52] = 16'h2528;
    cos_table[53] = 16'h2223;
    cos_table[54] = 16'h1F1A;
    cos_table[55] = 16'h1C0B;
    cos_table[56] = 16'h18F9;
    cos_table[57] = 16'h15E2;
    cos_table[58] = 16'h12C8;
    cos_table[59] = 16'h0FAB;
    cos_table[60] = 16'h0C8C;
    cos_table[61] = 16'h096A;
    cos_table[62] = 16'h0648;
    cos_table[63] = 16'h0324;
    cos_table[64] = 16'h0000;
    cos_table[65] = 16'hFCDC;
    cos_table[66] = 16'hF9B8;
    cos_table[67] = 16'hF696;
    cos_table[68] = 16'hF374;
    cos_table[69] = 16'hF055;
    cos_table[70] = 16'hED38;
    cos_table[71] = 16'hEA1E;
    cos_table[72] = 16'hE707;
    cos_table[73] = 16'hE3F5;
    cos_table[74] = 16'hE0E6;
    cos_table[75] = 16'hDDDD;
    cos_table[76] = 16'hDAD8;
    cos_table[77] = 16'hD7DA;
    cos_table[78] = 16'hD4E1;
    cos_table[79] = 16'hD1EF;
    cos_table[80] = 16'hCF05;
    cos_table[81] = 16'hCC21;
    cos_table[82] = 16'hC946;
    cos_table[83] = 16'hC674;
    cos_table[84] = 16'hC3AA;
    cos_table[85] = 16'hC0E9;
    cos_table[86] = 16'hBE32;
    cos_table[87] = 16'hBB86;
    cos_table[88] = 16'hB8E4;
    cos_table[89] = 16'hB64C;
    cos_table[90] = 16'hB3C1;
    cos_table[91] = 16'hB141;
    cos_table[92] = 16'hAECD;
    cos_table[93] = 16'hAC65;
    cos_table[94] = 16'hAA0B;
    cos_table[95] = 16'hA7BE;
    cos_table[96] = 16'hA57E;
    cos_table[97] = 16'hA34D;
    cos_table[98] = 16'hA129;
    cos_table[99] = 16'h9F15;
    cos_table[100] = 16'h9D0F;
    cos_table[101] = 16'h9B18;
    cos_table[102] = 16'h9931;
    cos_table[103] = 16'h975A;
    cos_table[104] = 16'h9593;
    cos_table[105] = 16'h93DD;
    cos_table[106] = 16'h9237;
    cos_table[107] = 16'h90A2;
    cos_table[108] = 16'h8F1E;
    cos_table[109] = 16'h8DAC;
    cos_table[110] = 16'h8C4B;
    cos_table[111] = 16'h8AFC;
    cos_table[112] = 16'h89BF;
    cos_table[113] = 16'h8895;
    cos_table[114] = 16'h877C;
    cos_table[115] = 16'h8677;
    cos_table[116] = 16'h8584;
    cos_table[117] = 16'h84A4;
    cos_table[118] = 16'h83D7;
    cos_table[119] = 16'h831D;
    cos_table[120] = 16'h8277;
    cos_table[121] = 16'h81E3;
    cos_table[122] = 16'h8164;
    cos_table[123] = 16'h80F7;
    cos_table[124] = 16'h809F;
    cos_table[125] = 16'h805A;
    cos_table[126] = 16'h8028;
    cos_table[127] = 16'h800B;
    cos_table[128] = 16'h8001;
    cos_table[129] = 16'h800B;
    cos_table[130] = 16'h8028;
    cos_table[131] = 16'h805A;
    cos_table[132] = 16'h809F;
    cos_table[133] = 16'h80F7;
    cos_table[134] = 16'h8164;
    cos_table[135] = 16'h81E3;
    cos_table[136] = 16'h8277;
    cos_table[137] = 16'h831D;
    cos_table[138] = 16'h83D7;
    cos_table[139] = 16'h84A4;
    cos_table[140] = 16'h8584;
    cos_table[141] = 16'h8677;
    cos_table[142] = 16'h877C;
    cos_table[143] = 16'h8895;
    cos_table[144] = 16'h89BF;
    cos_table[145] = 16'h8AFC;
    cos_table[146] = 16'h8C4B;
    cos_table[147] = 16'h8DAC;
    cos_table[148] = 16'h8F1E;
    cos_table[149] = 16'h90A2;
    cos_table[150] = 16'h9237;
    cos_table[151] = 16'h93DD;
    cos_table[152] = 16'h9593;
    cos_table[153] = 16'h975A;
    cos_table[154] = 16'h9931;
    cos_table[155] = 16'h9B18;
    cos_table[156] = 16'h9D0F;
    cos_table[157] = 16'h9F15;
    cos_table[158] = 16'hA129;
    cos_table[159] = 16'hA34D;
    cos_table[160] = 16'hA57E;
    cos_table[161] = 16'hA7BE;
    cos_table[162] = 16'hAA0B;
    cos_table[163] = 16'hAC65;
    cos_table[164] = 16'hAECD;
    cos_table[165] = 16'hB141;
    cos_table[166] = 16'hB3C1;
    cos_table[167] = 16'hB64C;
    cos_table[168] = 16'hB8E4;
    cos_table[169] = 16'hBB86;
    cos_table[170] = 16'hBE32;
    cos_table[171] = 16'hC0E9;
    cos_table[172] = 16'hC3AA;
    cos_table[173] = 16'hC674;
    cos_table[174] = 16'hC946;
    cos_table[175] = 16'hCC21;
    cos_table[176] = 16'hCF05;
    cos_table[177] = 16'hD1EF;
    cos_table[178] = 16'hD4E1;
    cos_table[179] = 16'hD7DA;
    cos_table[180] = 16'hDAD8;
    cos_table[181] = 16'hDDDD;
    cos_table[182] = 16'hE0E6;
    cos_table[183] = 16'hE3F5;
    cos_table[184] = 16'hE707;
    cos_table[185] = 16'hEA1E;
    cos_table[186] = 16'hED38;
    cos_table[187] = 16'hF055;
    cos_table[188] = 16'hF374;
    cos_table[189] = 16'hF696;
    cos_table[190] = 16'hF9B8;
    cos_table[191] = 16'hFCDC;
    cos_table[192] = 16'h0000;
    cos_table[193] = 16'h0324;
    cos_table[194] = 16'h0648;
    cos_table[195] = 16'h096A;
    cos_table[196] = 16'h0C8C;
    cos_table[197] = 16'h0FAB;
    cos_table[198] = 16'h12C8;
    cos_table[199] = 16'h15E2;
    cos_table[200] = 16'h18F9;
    cos_table[201] = 16'h1C0B;
    cos_table[202] = 16'h1F1A;
    cos_table[203] = 16'h2223;
    cos_table[204] = 16'h2528;
    cos_table[205] = 16'h2826;
    cos_table[206] = 16'h2B1F;
    cos_table[207] = 16'h2E11;
    cos_table[208] = 16'h30FB;
    cos_table[209] = 16'h33DF;
    cos_table[210] = 16'h36BA;
    cos_table[211] = 16'h398C;
    cos_table[212] = 16'h3C56;
    cos_table[213] = 16'h3F17;
    cos_table[214] = 16'h41CE;
    cos_table[215] = 16'h447A;
    cos_table[216] = 16'h471C;
    cos_table[217] = 16'h49B4;
    cos_table[218] = 16'h4C3F;
    cos_table[219] = 16'h4EBF;
    cos_table[220] = 16'h5133;
    cos_table[221] = 16'h539B;
    cos_table[222] = 16'h55F5;
    cos_table[223] = 16'h5842;
    cos_table[224] = 16'h5A82;
    cos_table[225] = 16'h5CB3;
    cos_table[226] = 16'h5ED7;
    cos_table[227] = 16'h60EB;
    cos_table[228] = 16'h62F1;
    cos_table[229] = 16'h64E8;
    cos_table[230] = 16'h66CF;
    cos_table[231] = 16'h68A6;
    cos_table[232] = 16'h6A6D;
    cos_table[233] = 16'h6C23;
    cos_table[234] = 16'h6DC9;
    cos_table[235] = 16'h6F5E;
    cos_table[236] = 16'h70E2;
    cos_table[237] = 16'h7254;
    cos_table[238] = 16'h73B5;
    cos_table[239] = 16'h7504;
    cos_table[240] = 16'h7641;
    cos_table[241] = 16'h776B;
    cos_table[242] = 16'h7884;
    cos_table[243] = 16'h7989;
    cos_table[244] = 16'h7A7C;
    cos_table[245] = 16'h7B5C;
    cos_table[246] = 16'h7C29;
    cos_table[247] = 16'h7CE3;
    cos_table[248] = 16'h7D89;
    cos_table[249] = 16'h7E1D;
    cos_table[250] = 16'h7E9C;
    cos_table[251] = 16'h7F09;
    cos_table[252] = 16'h7F61;
    cos_table[253] = 16'h7FA6;
    cos_table[254] = 16'h7FD8;
    cos_table[255] = 16'h7FF5; //(cosine table initialization code)
end

// Calculate Hamming window coefficients using a combinational always block
integer i;
always @(*) begin
    for (i = 0; i < 256; i = i + 1) begin
        if (i < frame_size) begin
            reg [15:0] cosine;
            reg [23:0] idx;

            // Calculate the cosine index based on i and frame_size
            idx = (i * 256) / (frame_size - 1);

            // Look up the cosine value from the pre-computed table
            cosine = cos_table[idx[7:0]];

            // Calculate the Hamming window coefficient
            hamming_window[i] = Q15_ONE[15:0] - ((Q15_HALF[15:0] * cosine) >>> 15);
        end else begin
            hamming_window[i] = 16'h0;
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
`endif