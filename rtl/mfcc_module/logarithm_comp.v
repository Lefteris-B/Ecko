`ifndef LOGARITHM_COMP_V
`define LOGARITHM_COMP_V

module logarithm_comp (
    input wire clk,
    input wire rst_n,
    input wire [31:0] mel_fbank_out,
    input wire mel_fbank_valid,
    output reg [31:0] log_out,
    output reg log_valid
);

// Constants
localparam LUT_SIZE = 1024;  // Size of the lookup table
localparam LUT_ADDR_WIDTH = $clog2(LUT_SIZE);
localparam LUT_DATA_WIDTH = 16;  // Width of the logarithm values in the lookup table

// Logarithm lookup table
reg [LUT_DATA_WIDTH-1:0] log_lut [0:LUT_SIZE-1];

// Logarithm computation pipeline
reg [LUT_ADDR_WIDTH-1:0] lut_addr;
reg [LUT_DATA_WIDTH-1:0] lut_data;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lut_addr <= 'h0;
        lut_data <= 'h0;
        log_out <= 32'h0;
        log_valid <= 1'b0;
    end else if (mel_fbank_valid) begin
        lut_addr <= mel_fbank_out[LUT_ADDR_WIDTH+9:10];  // Use upper bits as LUT address
        lut_data <= log_lut[lut_addr];
        log_out <= {16'h0, lut_data};  // Concatenate with zeros to form 32-bit output
        log_valid <= 1'b1;
    end else begin
        log_valid <= 1'b0;
    end
end


// Initialize logarithm lookup table
initial begin
    log_lut[0] = 16'h0000;
    log_lut[1] = 16'hAFA1;
    log_lut[2] = 16'h085A;
    log_lut[3] = 16'h3C40;
    log_lut[4] = 16'h6113;
    log_lut[5] = 16'h7DA3;
    log_lut[6] = 16'h94F9;
    log_lut[7] = 16'hA8B4;
    log_lut[8] = 16'hB9CC;
    log_lut[9] = 16'hC8DF;
    log_lut[10] = 16'hD65C;
    log_lut[11] = 16'hE28F;
    log_lut[12] = 16'hEDB2;
    log_lut[13] = 16'hF7F1;
    log_lut[14] = 16'h016D;
    log_lut[15] = 16'h0A42;
    log_lut[16] = 16'h1285;
    log_lut[17] = 16'h1A47;
    log_lut[18] = 16'h2198;
    log_lut[19] = 16'h2884;
    log_lut[20] = 16'h2F15;
    log_lut[21] = 16'h3554;
    log_lut[22] = 16'h3B48;
    log_lut[23] = 16'h40F9;
    log_lut[24] = 16'h466B;
    log_lut[25] = 16'h4BA5;
    log_lut[26] = 16'h50AA;
    log_lut[27] = 16'h557F;
    log_lut[28] = 16'h5A26;
    log_lut[29] = 16'h5EA4;
    log_lut[30] = 16'h62FB;
    log_lut[31] = 16'h672E;
    log_lut[32] = 16'h6B3E;
    log_lut[33] = 16'h6F2E;
    log_lut[34] = 16'h7300;
    log_lut[35] = 16'h76B6;
    log_lut[36] = 16'h7A51;
    log_lut[37] = 16'h7DD3;
    log_lut[38] = 16'h813D;
    log_lut[39] = 16'h8490;
    log_lut[40] = 16'h87CE;
    log_lut[41] = 16'h8AF7;
    log_lut[42] = 16'h8E0D;
    log_lut[43] = 16'h9110;
    log_lut[44] = 16'h9401;
    log_lut[45] = 16'h96E1;
    log_lut[46] = 16'h99B2;
    log_lut[47] = 16'h9C72;
    log_lut[48] = 16'h9F24;
    log_lut[49] = 16'hA1C8;
    log_lut[50] = 16'hA45E;
    log_lut[51] = 16'hA6E7;
    log_lut[52] = 16'hA963;
    log_lut[53] = 16'hABD3;
    log_lut[54] = 16'hAE38;
    log_lut[55] = 16'hB091;
    log_lut[56] = 16'hB2DF;
    log_lut[57] = 16'hB523;
    log_lut[58] = 16'hB75D;
    log_lut[59] = 16'hB98D;
    log_lut[60] = 16'hBBB4;
    log_lut[61] = 16'hBDD2;
    log_lut[62] = 16'hBFE7;
    log_lut[63] = 16'hC1F3;
    log_lut[64] = 16'hC3F7;
    log_lut[65] = 16'hC5F3;
    log_lut[66] = 16'hC7E7;
    log_lut[67] = 16'hC9D4;
    log_lut[68] = 16'hCBB9;
    log_lut[69] = 16'hCD98;
    log_lut[70] = 16'hCF6F;
    log_lut[71] = 16'hD140;
    log_lut[72] = 16'hD30A;
    log_lut[73] = 16'hD4CE;
    log_lut[74] = 16'hD68C;
    log_lut[75] = 16'hD844;
    log_lut[76] = 16'hD9F6;
    log_lut[77] = 16'hDBA2;
    log_lut[78] = 16'hDD49;
    log_lut[79] = 16'hDEEB;
    log_lut[80] = 16'hE087;
    log_lut[81] = 16'hE21E;
    log_lut[82] = 16'hE3B0;
    log_lut[83] = 16'hE53D;
    log_lut[84] = 16'hE6C6;
    log_lut[85] = 16'hE849;
    log_lut[86] = 16'hE9C9;
    log_lut[87] = 16'hEB44;
    log_lut[88] = 16'hECBA;
    log_lut[89] = 16'hEE2C;
    log_lut[90] = 16'hEF9A;
    log_lut[91] = 16'hF105;
    log_lut[92] = 16'hF26B;
    log_lut[93] = 16'hF3CD;
    log_lut[94] = 16'hF52B;
    log_lut[95] = 16'hF686;
    log_lut[96] = 16'hF7DD;
    log_lut[97] = 16'hF931;
    log_lut[98] = 16'hFA81;
    log_lut[99] = 16'hFBCE;
    log_lut[100] = 16'hFD17;
    log_lut[101] = 16'hFE5D;
    log_lut[102] = 16'hFFA0;
    log_lut[103] = 16'h00DF;
    log_lut[104] = 16'h021C;
    log_lut[105] = 16'h0356;
    log_lut[106] = 16'h048C;
    log_lut[107] = 16'h05C0;
    log_lut[108] = 16'h06F1;
    log_lut[109] = 16'h081F;
    log_lut[110] = 16'h094A;
    log_lut[111] = 16'h0A73;
    log_lut[112] = 16'h0B98;
    log_lut[113] = 16'h0CBC;
    log_lut[114] = 16'h0DDC;
    log_lut[115] = 16'h0EFB;
    log_lut[116] = 16'h1016;
    log_lut[117] = 16'h1130;
    log_lut[118] = 16'h1246;
    log_lut[119] = 16'h135B;
    log_lut[120] = 16'h146D;
    log_lut[121] = 16'h157D;
    log_lut[122] = 16'h168B;
    log_lut[123] = 16'h1796;
    log_lut[124] = 16'h18A0;
    log_lut[125] = 16'h19A7;
    log_lut[126] = 16'h1AAC;
    log_lut[127] = 16'h1BAF;
    log_lut[128] = 16'h1CB0;
    log_lut[129] = 16'h1DAF;
    log_lut[130] = 16'h1EAC;
    log_lut[131] = 16'h1FA7;
    log_lut[132] = 16'h20A0;
    log_lut[133] = 16'h2198;
    log_lut[134] = 16'h228D;
    log_lut[135] = 16'h2381;
    log_lut[136] = 16'h2473;
    log_lut[137] = 16'h2563;
    log_lut[138] = 16'h2651;
    log_lut[139] = 16'h273D;
    log_lut[140] = 16'h2828;
    log_lut[141] = 16'h2912;
    log_lut[142] = 16'h29F9;
    log_lut[143] = 16'h2ADF;
    log_lut[144] = 16'h2BC3;
    log_lut[145] = 16'h2CA6;
    log_lut[146] = 16'h2D87;
    log_lut[147] = 16'h2E67;
    log_lut[148] = 16'h2F45;
    log_lut[149] = 16'h3022;
    log_lut[150] = 16'h30FD;
    log_lut[151] = 16'h31D7;
    log_lut[152] = 16'h32AF;
    log_lut[153] = 16'h3386;
    log_lut[154] = 16'h345C;
    log_lut[155] = 16'h3530;
    log_lut[156] = 16'h3602;
    log_lut[157] = 16'h36D4;
    log_lut[158] = 16'h37A4;
    log_lut[159] = 16'h3873;
    log_lut[160] = 16'h3940;
    log_lut[161] = 16'h3A0C;
    log_lut[162] = 16'h3AD7;
    log_lut[163] = 16'h3BA1;
    log_lut[164] = 16'h3C69;
    log_lut[165] = 16'h3D30;
    log_lut[166] = 16'h3DF6;
    log_lut[167] = 16'h3EBB;
    log_lut[168] = 16'h3F7F;
    log_lut[169] = 16'h4041;
    log_lut[170] = 16'h4102;
    log_lut[171] = 16'h41C3;
    log_lut[172] = 16'h4282;
    log_lut[173] = 16'h4340;
    log_lut[174] = 16'h43FD;
    log_lut[175] = 16'h44B8;
    log_lut[176] = 16'h4573;
    log_lut[177] = 16'h462D;
    log_lut[178] = 16'h46E5;
    log_lut[179] = 16'h479D;
    log_lut[180] = 16'h4853;
    log_lut[181] = 16'h4909;
    log_lut[182] = 16'h49BE;
    log_lut[183] = 16'h4A71;
    log_lut[184] = 16'h4B24;
    log_lut[185] = 16'h4BD5;
    log_lut[186] = 16'h4C86;
    log_lut[187] = 16'h4D36;
    log_lut[188] = 16'h4DE4;
    log_lut[189] = 16'h4E92;
    log_lut[190] = 16'h4F3F;
    log_lut[191] = 16'h4FEB;
    log_lut[192] = 16'h5096;
    log_lut[193] = 16'h5140;
    log_lut[194] = 16'h51EA;
    log_lut[195] = 16'h5292;
    log_lut[196] = 16'h533A;
    log_lut[197] = 16'h53E1;
    log_lut[198] = 16'h5487;
    log_lut[199] = 16'h552C;
    log_lut[200] = 16'h55D0;
    log_lut[201] = 16'h5673;
    log_lut[202] = 16'h5716;
    log_lut[203] = 16'h57B8;
    log_lut[204] = 16'h5859;
    log_lut[205] = 16'h58F9;
    log_lut[206] = 16'h5999;
    log_lut[207] = 16'h5A37;
    log_lut[208] = 16'h5AD5;
    log_lut[209] = 16'h5B72;
    log_lut[210] = 16'h5C0F;
    log_lut[211] = 16'h5CAA;
    log_lut[212] = 16'h5D45;
    log_lut[213] = 16'h5DDF;
    log_lut[214] = 16'h5E79;
    log_lut[215] = 16'h5F12;
    log_lut[216] = 16'h5FAA;
    log_lut[217] = 16'h6041;
    log_lut[218] = 16'h60D8;
    log_lut[219] = 16'h616E;
    log_lut[220] = 16'h6203;
    log_lut[221] = 16'h6298;
    log_lut[222] = 16'h632C;
    log_lut[223] = 16'h63BF;
    log_lut[224] = 16'h6451;
    log_lut[225] = 16'h64E3;
    log_lut[226] = 16'h6575;
    log_lut[227] = 16'h6605;
    log_lut[228] = 16'h6695;
    log_lut[229] = 16'h6725;
    log_lut[230] = 16'h67B4;
    log_lut[231] = 16'h6842;
    log_lut[232] = 16'h68CF;
    log_lut[233] = 16'h695C;
    log_lut[234] = 16'h69E9;
    log_lut[235] = 16'h6A74;
    log_lut[236] = 16'h6AFF;
    log_lut[237] = 16'h6B8A;
    log_lut[238] = 16'h6C14;
    log_lut[239] = 16'h6C9D;
    log_lut[240] = 16'h6D26;
    log_lut[241] = 16'h6DAE;
    log_lut[242] = 16'h6E36;
    log_lut[243] = 16'h6EBD;
    log_lut[244] = 16'h6F44;
    log_lut[245] = 16'h6FCA;
    log_lut[246] = 16'h704F;
    log_lut[247] = 16'h70D4;
    log_lut[248] = 16'h7159;
    log_lut[249] = 16'h71DD;
    log_lut[250] = 16'h7260;
    log_lut[251] = 16'h72E3;
    log_lut[252] = 16'h7365;
    log_lut[253] = 16'h73E7;
    log_lut[254] = 16'h7468;
    log_lut[255] = 16'h74E9;
    log_lut[256] = 16'h7569;
    log_lut[257] = 16'h75E9;
    log_lut[258] = 16'h7668;
    log_lut[259] = 16'h76E7;
    log_lut[260] = 16'h7765;
    log_lut[261] = 16'h77E3;
    log_lut[262] = 16'h7860;
    log_lut[263] = 16'h78DD;
    log_lut[264] = 16'h7959;
    log_lut[265] = 16'h79D5;
    log_lut[266] = 16'h7A51;
    log_lut[267] = 16'h7ACC;
    log_lut[268] = 16'h7B46;
    log_lut[269] = 16'h7BC0;
    log_lut[270] = 16'h7C3A;
    log_lut[271] = 16'h7CB3;
    log_lut[272] = 16'h7D2C;
    log_lut[273] = 16'h7DA4;
    log_lut[274] = 16'h7E1C;
    log_lut[275] = 16'h7E93;
    log_lut[276] = 16'h7F0A;
    log_lut[277] = 16'h7F80;
    log_lut[278] = 16'h7FF7;
    log_lut[279] = 16'h806C;
    log_lut[280] = 16'h80E1;
    log_lut[281] = 16'h8156;
    log_lut[282] = 16'h81CB;
    log_lut[283] = 16'h823F;
    log_lut[284] = 16'h82B2;
    log_lut[285] = 16'h8325;
    log_lut[286] = 16'h8398;
    log_lut[287] = 16'h840B;
    log_lut[288] = 16'h847D;
    log_lut[289] = 16'h84EE;
    log_lut[290] = 16'h855F;
    log_lut[291] = 16'h85D0;
    log_lut[292] = 16'h8641;
    log_lut[293] = 16'h86B1;
    log_lut[294] = 16'h8720;
    log_lut[295] = 16'h878F;
    log_lut[296] = 16'h87FE;
    log_lut[297] = 16'h886D;
    log_lut[298] = 16'h88DB;
    log_lut[299] = 16'h8949;
    log_lut[300] = 16'h89B6;
    log_lut[301] = 16'h8A23;
    log_lut[302] = 16'h8A90;
    log_lut[303] = 16'h8AFC;
    log_lut[304] = 16'h8B68;
    log_lut[305] = 16'h8BD4;
    log_lut[306] = 16'h8C3F;
    log_lut[307] = 16'h8CAA;
    log_lut[308] = 16'h8D15;
    log_lut[309] = 16'h8D7F;
    log_lut[310] = 16'h8DE9;
    log_lut[311] = 16'h8E52;
    log_lut[312] = 16'h8EBB;
    log_lut[313] = 16'h8F24;
    log_lut[314] = 16'h8F8D;
    log_lut[315] = 16'h8FF5;
    log_lut[316] = 16'h905D;
    log_lut[317] = 16'h90C4;
    log_lut[318] = 16'h912C;
    log_lut[319] = 16'h9192;
    log_lut[320] = 16'h91F9;
    log_lut[321] = 16'h925F;
    log_lut[322] = 16'h92C5;
    log_lut[323] = 16'h932B;
    log_lut[324] = 16'h9390;
    log_lut[325] = 16'h93F5;
    log_lut[326] = 16'h945A;
    log_lut[327] = 16'h94BE;
    log_lut[328] = 16'h9522;
    log_lut[329] = 16'h9586;
    log_lut[330] = 16'h95E9;
    log_lut[331] = 16'h964C;
    log_lut[332] = 16'h96AF;
    log_lut[333] = 16'h9712;
    log_lut[334] = 16'h9774;
    log_lut[335] = 16'h97D6;
    log_lut[336] = 16'h9838;
    log_lut[337] = 16'h9899;
    log_lut[338] = 16'h98FA;
    log_lut[339] = 16'h995B;
    log_lut[340] = 16'h99BC;
    log_lut[341] = 16'h9A1C;
    log_lut[342] = 16'h9A7C;
    log_lut[343] = 16'h9ADB;
    log_lut[344] = 16'h9B3B;
    log_lut[345] = 16'h9B9A;
    log_lut[346] = 16'h9BF9;
    log_lut[347] = 16'h9C57;
    log_lut[348] = 16'h9CB6;
    log_lut[349] = 16'h9D14;
    log_lut[350] = 16'h9D71;
    log_lut[351] = 16'h9DCF;
    log_lut[352] = 16'h9E2C;
    log_lut[353] = 16'h9E89;
    log_lut[354] = 16'h9EE6;
    log_lut[355] = 16'h9F42;
    log_lut[356] = 16'h9F9E;
    log_lut[357] = 16'h9FFA;
    log_lut[358] = 16'hA056;
    log_lut[359] = 16'hA0B1;
    log_lut[360] = 16'hA10D;
    log_lut[361] = 16'hA167;
    log_lut[362] = 16'hA1C2;
    log_lut[363] = 16'hA21C;
    log_lut[364] = 16'hA277;
    log_lut[365] = 16'hA2D0;
    log_lut[366] = 16'hA32A;
    log_lut[367] = 16'hA384;
    log_lut[368] = 16'hA3DD;
    log_lut[369] = 16'hA436;
    log_lut[370] = 16'hA48E;
    log_lut[371] = 16'hA4E7;
    log_lut[372] = 16'hA53F;
    log_lut[373] = 16'hA597;
    log_lut[374] = 16'hA5EF;
    log_lut[375] = 16'hA646;
    log_lut[376] = 16'hA69D;
    log_lut[377] = 16'hA6F4;
    log_lut[378] = 16'hA74B;
    log_lut[379] = 16'hA7A2;
    log_lut[380] = 16'hA7F8;
    log_lut[381] = 16'hA84E;
    log_lut[382] = 16'hA8A4;
    log_lut[383] = 16'hA8FA;
    log_lut[384] = 16'hA94F;
    log_lut[385] = 16'hA9A5;
    log_lut[386] = 16'hA9FA;
    log_lut[387] = 16'hAA4E;
    log_lut[388] = 16'hAAA3;
    log_lut[389] = 16'hAAF7;
    log_lut[390] = 16'hAB4B;
    log_lut[391] = 16'hAB9F;
    log_lut[392] = 16'hABF3;
    log_lut[393] = 16'hAC46;
    log_lut[394] = 16'hAC9A;
    log_lut[395] = 16'hACED;
    log_lut[396] = 16'hAD40;
    log_lut[397] = 16'hAD92;
    log_lut[398] = 16'hADE5;
    log_lut[399] = 16'hAE37;
    log_lut[400] = 16'hAE89;
    log_lut[401] = 16'hAEDB;
    log_lut[402] = 16'hAF2C;
    log_lut[403] = 16'hAF7E;
    log_lut[404] = 16'hAFCF;
    log_lut[405] = 16'hB020;
    log_lut[406] = 16'hB071;
    log_lut[407] = 16'hB0C1;
    log_lut[408] = 16'hB112;
    log_lut[409] = 16'hB162;
    log_lut[410] = 16'hB1B2;
    log_lut[411] = 16'hB202;
    log_lut[412] = 16'hB252;
    log_lut[413] = 16'hB2A1;
    log_lut[414] = 16'hB2F0;
    log_lut[415] = 16'hB33F;
    log_lut[416] = 16'hB38E;
    log_lut[417] = 16'hB3DD;
    log_lut[418] = 16'hB42B;
    log_lut[419] = 16'hB47A;
    log_lut[420] = 16'hB4C8;
    log_lut[421] = 16'hB516;
    log_lut[422] = 16'hB563;
    log_lut[423] = 16'hB5B1;
    log_lut[424] = 16'hB5FE;
    log_lut[425] = 16'hB64C;
    log_lut[426] = 16'hB699;
    log_lut[427] = 16'hB6E5;
    log_lut[428] = 16'hB732;
    log_lut[429] = 16'hB77E;
    log_lut[430] = 16'hB7CB;
    log_lut[431] = 16'hB817;
    log_lut[432] = 16'hB863;
    log_lut[433] = 16'hB8AF;
    log_lut[434] = 16'hB8FA;
    log_lut[435] = 16'hB946;
    log_lut[436] = 16'hB991;
    log_lut[437] = 16'hB9DC;
    log_lut[438] = 16'hBA27;
    log_lut[439] = 16'hBA72;
    log_lut[440] = 16'hBABC;
    log_lut[441] = 16'hBB06;
    log_lut[442] = 16'hBB51;
    log_lut[443] = 16'hBB9B;
    log_lut[444] = 16'hBBE5;
    log_lut[445] = 16'hBC2E;
    log_lut[446] = 16'hBC78;
    log_lut[447] = 16'hBCC1;
    log_lut[448] = 16'hBD0B;
    log_lut[449] = 16'hBD54;
    log_lut[450] = 16'hBD9C;
    log_lut[451] = 16'hBDE5;
    log_lut[452] = 16'hBE2E;
    log_lut[453] = 16'hBE76;
    log_lut[454] = 16'hBEBE;
    log_lut[455] = 16'hBF07;
    log_lut[456] = 16'hBF4F;
    log_lut[457] = 16'hBF96;
    log_lut[458] = 16'hBFDE;
    log_lut[459] = 16'hC025;
    log_lut[460] = 16'hC06D;
    log_lut[461] = 16'hC0B4;
    log_lut[462] = 16'hC0FB;
    log_lut[463] = 16'hC142;
    log_lut[464] = 16'hC188;
    log_lut[465] = 16'hC1CF;
    log_lut[466] = 16'hC215;
    log_lut[467] = 16'hC25C;
    log_lut[468] = 16'hC2A2;
    log_lut[469] = 16'hC2E8;
    log_lut[470] = 16'hC32D;
    log_lut[471] = 16'hC373;
    log_lut[472] = 16'hC3B9;
    log_lut[473] = 16'hC3FE;
    log_lut[474] = 16'hC443;
    log_lut[475] = 16'hC488;
    log_lut[476] = 16'hC4CD;
    log_lut[477] = 16'hC512;
    log_lut[478] = 16'hC556;
    log_lut[479] = 16'hC59B;
    log_lut[480] = 16'hC5DF;
    log_lut[481] = 16'hC623;
    log_lut[482] = 16'hC668;
    log_lut[483] = 16'hC6AB;
    log_lut[484] = 16'hC6EF;
    log_lut[485] = 16'hC733;
    log_lut[486] = 16'hC776;
    log_lut[487] = 16'hC7BA;
    log_lut[488] = 16'hC7FD;
    log_lut[489] = 16'hC840;
    log_lut[490] = 16'hC883;
    log_lut[491] = 16'hC8C6;
    log_lut[492] = 16'hC908;
    log_lut[493] = 16'hC94B;
    log_lut[494] = 16'hC98D;
    log_lut[495] = 16'hC9D0;
    log_lut[496] = 16'hCA12;
    log_lut[497] = 16'hCA54;
    log_lut[498] = 16'hCA96;
    log_lut[499] = 16'hCAD7;
    log_lut[500] = 16'hCB19;
    log_lut[501] = 16'hCB5A;
    log_lut[502] = 16'hCB9C;
    log_lut[503] = 16'hCBDD;
    log_lut[504] = 16'hCC1E;
    log_lut[505] = 16'hCC5F;
    log_lut[506] = 16'hCCA0;
    log_lut[507] = 16'hCCE1;
    log_lut[508] = 16'hCD21;
    log_lut[509] = 16'hCD62;
    log_lut[510] = 16'hCDA2;
    log_lut[511] = 16'hCDE2;
    log_lut[512] = 16'hCE22;
    log_lut[513] = 16'hCE62;
    log_lut[514] = 16'hCEA2;
    log_lut[515] = 16'hCEE2;
    log_lut[516] = 16'hCF21;
    log_lut[517] = 16'hCF61;
    log_lut[518] = 16'hCFA0;
    log_lut[519] = 16'hCFDF;
    log_lut[520] = 16'hD01E;
    log_lut[521] = 16'hD05D;
    log_lut[522] = 16'hD09C;
    log_lut[523] = 16'hD0DB;
    log_lut[524] = 16'hD119;
    log_lut[525] = 16'hD158;
    log_lut[526] = 16'hD196;
    log_lut[527] = 16'hD1D4;
    log_lut[528] = 16'hD212;
    log_lut[529] = 16'hD250;
    log_lut[530] = 16'hD28E;
    log_lut[531] = 16'hD2CC;
    log_lut[532] = 16'hD30A;
    log_lut[533] = 16'hD347;
    log_lut[534] = 16'hD385;
    log_lut[535] = 16'hD3C2;
    log_lut[536] = 16'hD3FF;
    log_lut[537] = 16'hD43C;
    log_lut[538] = 16'hD479;
    log_lut[539] = 16'hD4B6;
    log_lut[540] = 16'hD4F3;
    log_lut[541] = 16'hD52F;
    log_lut[542] = 16'hD56C;
    log_lut[543] = 16'hD5A8;
    log_lut[544] = 16'hD5E5;
    log_lut[545] = 16'hD621;
    log_lut[546] = 16'hD65D;
    log_lut[547] = 16'hD699;
    log_lut[548] = 16'hD6D5;
    log_lut[549] = 16'hD710;
    log_lut[550] = 16'hD74C;
    log_lut[551] = 16'hD788;
    log_lut[552] = 16'hD7C3;
    log_lut[553] = 16'hD7FE;
    log_lut[554] = 16'hD83A;
    log_lut[555] = 16'hD875;
    log_lut[556] = 16'hD8B0;
    log_lut[557] = 16'hD8EA;
    log_lut[558] = 16'hD925;
    log_lut[559] = 16'hD960;
    log_lut[560] = 16'hD99A;
    log_lut[561] = 16'hD9D5;
    log_lut[562] = 16'hDA0F;
    log_lut[563] = 16'hDA4A;
    log_lut[564] = 16'hDA84;
    log_lut[565] = 16'hDABE;
    log_lut[566] = 16'hDAF8;
    log_lut[567] = 16'hDB32;
    log_lut[568] = 16'hDB6B;
    log_lut[569] = 16'hDBA5;
    log_lut[570] = 16'hDBDE;
    log_lut[571] = 16'hDC18;
    log_lut[572] = 16'hDC51;
    log_lut[573] = 16'hDC8A;
    log_lut[574] = 16'hDCC4;
    log_lut[575] = 16'hDCFD;
    log_lut[576] = 16'hDD36;
    log_lut[577] = 16'hDD6E;
    log_lut[578] = 16'hDDA7;
    log_lut[579] = 16'hDDE0;
    log_lut[580] = 16'hDE18;
    log_lut[581] = 16'hDE51;
    log_lut[582] = 16'hDE89;
    log_lut[583] = 16'hDEC1;
    log_lut[584] = 16'hDEFA;
    log_lut[585] = 16'hDF32;
    log_lut[586] = 16'hDF6A;
    log_lut[587] = 16'hDFA1;
    log_lut[588] = 16'hDFD9;
    log_lut[589] = 16'hE011;
    log_lut[590] = 16'hE049;
    log_lut[591] = 16'hE080;
    log_lut[592] = 16'hE0B7;
    log_lut[593] = 16'hE0EF;
    log_lut[594] = 16'hE126;
    log_lut[595] = 16'hE15D;
    log_lut[596] = 16'hE194;
    log_lut[597] = 16'hE1CB;
    log_lut[598] = 16'hE202;
    log_lut[599] = 16'hE239;
    log_lut[600] = 16'hE26F;
    log_lut[601] = 16'hE2A6;
    log_lut[602] = 16'hE2DC;
    log_lut[603] = 16'hE313;
    log_lut[604] = 16'hE349;
    log_lut[605] = 16'hE37F;
    log_lut[606] = 16'hE3B5;
    log_lut[607] = 16'hE3EB;
    log_lut[608] = 16'hE421;
    log_lut[609] = 16'hE457;
    log_lut[610] = 16'hE48D;
    log_lut[611] = 16'hE4C3;
    log_lut[612] = 16'hE4F8;
    log_lut[613] = 16'hE52E;
    log_lut[614] = 16'hE563;
    log_lut[615] = 16'hE598;
    log_lut[616] = 16'hE5CE;
    log_lut[617] = 16'hE603;
    log_lut[618] = 16'hE638;
    log_lut[619] = 16'hE66D;
    log_lut[620] = 16'hE6A2;
    log_lut[621] = 16'hE6D7;
    log_lut[622] = 16'hE70B;
    log_lut[623] = 16'hE740;
    log_lut[624] = 16'hE774;
    log_lut[625] = 16'hE7A9;
    log_lut[626] = 16'hE7DD;
    log_lut[627] = 16'hE812;
    log_lut[628] = 16'hE846;
    log_lut[629] = 16'hE87A;
    log_lut[630] = 16'hE8AE;
    log_lut[631] = 16'hE8E2;
    log_lut[632] = 16'hE916;
    log_lut[633] = 16'hE94A;
    log_lut[634] = 16'hE97D;
    log_lut[635] = 16'hE9B1;
    log_lut[636] = 16'hE9E5;
    log_lut[637] = 16'hEA18;
    log_lut[638] = 16'hEA4B;
    log_lut[639] = 16'hEA7F;
    log_lut[640] = 16'hEAB2;
    log_lut[641] = 16'hEAE5;
    log_lut[642] = 16'hEB18;
    log_lut[643] = 16'hEB4B;
    log_lut[644] = 16'hEB7E;
    log_lut[645] = 16'hEBB1;
    log_lut[646] = 16'hEBE4;
    log_lut[647] = 16'hEC16;
    log_lut[648] = 16'hEC49;
    log_lut[649] = 16'hEC7C;
    log_lut[650] = 16'hECAE;
    log_lut[651] = 16'hECE0;
    log_lut[652] = 16'hED13;
    log_lut[653] = 16'hED45;
    log_lut[654] = 16'hED77;
    log_lut[655] = 16'hEDA9;
    log_lut[656] = 16'hEDDB;
    log_lut[657] = 16'hEE0D;
    log_lut[658] = 16'hEE3F;
    log_lut[659] = 16'hEE71;
    log_lut[660] = 16'hEEA2;
    log_lut[661] = 16'hEED4;
    log_lut[662] = 16'hEF06;
    log_lut[663] = 16'hEF37;
    log_lut[664] = 16'hEF68;
    log_lut[665] = 16'hEF9A;
    log_lut[666] = 16'hEFCB;
    log_lut[667] = 16'hEFFC;
    log_lut[668] = 16'hF02D;
    log_lut[669] = 16'hF05E;
    log_lut[670] = 16'hF08F;
    log_lut[671] = 16'hF0C0;
    log_lut[672] = 16'hF0F1;
    log_lut[673] = 16'hF122;
    log_lut[674] = 16'hF152;
    log_lut[675] = 16'hF183;
    log_lut[676] = 16'hF1B3;
    log_lut[677] = 16'hF1E4;
    log_lut[678] = 16'hF214;
    log_lut[679] = 16'hF244;
    log_lut[680] = 16'hF275;
    log_lut[681] = 16'hF2A5;
    log_lut[682] = 16'hF2D5;
    log_lut[683] = 16'hF305;
    log_lut[684] = 16'hF335;
    log_lut[685] = 16'hF365;
    log_lut[686] = 16'hF394;
    log_lut[687] = 16'hF3C4;
    log_lut[688] = 16'hF3F4;
    log_lut[689] = 16'hF423;
    log_lut[690] = 16'hF453;
    log_lut[691] = 16'hF482;
    log_lut[692] = 16'hF4B2;
    log_lut[693] = 16'hF4E1;
    log_lut[694] = 16'hF510;
    log_lut[695] = 16'hF540;
    log_lut[696] = 16'hF56F;
    log_lut[697] = 16'hF59E;
    log_lut[698] = 16'hF5CD;
    log_lut[699] = 16'hF5FC;
    log_lut[700] = 16'hF62A;
    log_lut[701] = 16'hF659;
    log_lut[702] = 16'hF688;
    log_lut[703] = 16'hF6B7;
    log_lut[704] = 16'hF6E5;
    log_lut[705] = 16'hF714;
    log_lut[706] = 16'hF742;
    log_lut[707] = 16'hF771;
    log_lut[708] = 16'hF79F;
    log_lut[709] = 16'hF7CD;
    log_lut[710] = 16'hF7FB;
    log_lut[711] = 16'hF829;
    log_lut[712] = 16'hF857;
    log_lut[713] = 16'hF885;
    log_lut[714] = 16'hF8B3;
    log_lut[715] = 16'hF8E1;
    log_lut[716] = 16'hF90F;
    log_lut[717] = 16'hF93D;
    log_lut[718] = 16'hF96A;
    log_lut[719] = 16'hF998;
    log_lut[720] = 16'hF9C6;
    log_lut[721] = 16'hF9F3;
    log_lut[722] = 16'hFA20;
    log_lut[723] = 16'hFA4E;
    log_lut[724] = 16'hFA7B;
    log_lut[725] = 16'hFAA8;
    log_lut[726] = 16'hFAD5;
    log_lut[727] = 16'hFB03;
    log_lut[728] = 16'hFB30;
    log_lut[729] = 16'hFB5D;
    log_lut[730] = 16'hFB8A;
    log_lut[731] = 16'hFBB6;
    log_lut[732] = 16'hFBE3;
    log_lut[733] = 16'hFC10;
    log_lut[734] = 16'hFC3D;
    log_lut[735] = 16'hFC69;
    log_lut[736] = 16'hFC96;
    log_lut[737] = 16'hFCC2;
    log_lut[738] = 16'hFCEF;
    log_lut[739] = 16'hFD1B;
    log_lut[740] = 16'hFD47;
    log_lut[741] = 16'hFD74;
    log_lut[742] = 16'hFDA0;
    log_lut[743] = 16'hFDCC;
    log_lut[744] = 16'hFDF8;
    log_lut[745] = 16'hFE24;
    log_lut[746] = 16'hFE50;
    log_lut[747] = 16'hFE7C;
    log_lut[748] = 16'hFEA8;
    log_lut[749] = 16'hFED3;
    log_lut[750] = 16'hFEFF;
    log_lut[751] = 16'hFF2B;
    log_lut[752] = 16'hFF56;
    log_lut[753] = 16'hFF82;
    log_lut[754] = 16'hFFAE;
    log_lut[755] = 16'hFFD9;
    log_lut[756] = 16'h0004;
    log_lut[757] = 16'h0030;
    log_lut[758] = 16'h005B;
    log_lut[759] = 16'h0086;
    log_lut[760] = 16'h00B1;
    log_lut[761] = 16'h00DC;
    log_lut[762] = 16'h0107;
    log_lut[763] = 16'h0132;
    log_lut[764] = 16'h015D;
    log_lut[765] = 16'h0188;
    log_lut[766] = 16'h01B3;
    log_lut[767] = 16'h01DE;
    log_lut[768] = 16'h0208;
    log_lut[769] = 16'h0233;
    log_lut[770] = 16'h025E;
    log_lut[771] = 16'h0288;
    log_lut[772] = 16'h02B3;
    log_lut[773] = 16'h02DD;
    log_lut[774] = 16'h0307;
    log_lut[775] = 16'h0332;
    log_lut[776] = 16'h035C;
    log_lut[777] = 16'h0386;
    log_lut[778] = 16'h03B0;
    log_lut[779] = 16'h03DA;
    log_lut[780] = 16'h0404;
    log_lut[781] = 16'h042E;
    log_lut[782] = 16'h0458;
    log_lut[783] = 16'h0482;
    log_lut[784] = 16'h04AC;
    log_lut[785] = 16'h04D6;
    log_lut[786] = 16'h04FF;
    log_lut[787] = 16'h0529;
    log_lut[788] = 16'h0553;
    log_lut[789] = 16'h057C;
    log_lut[790] = 16'h05A6;
    log_lut[791] = 16'h05CF;
    log_lut[792] = 16'h05F9;
    log_lut[793] = 16'h0622;
    log_lut[794] = 16'h064B;
    log_lut[795] = 16'h0675;
    log_lut[796] = 16'h069E;
    log_lut[797] = 16'h06C7;
    log_lut[798] = 16'h06F0;
    log_lut[799] = 16'h0719;
    log_lut[800] = 16'h0742;
    log_lut[801] = 16'h076B;
    log_lut[802] = 16'h0794;
    log_lut[803] = 16'h07BD;
    log_lut[804] = 16'h07E5;
    log_lut[805] = 16'h080E;
    log_lut[806] = 16'h0837;
    log_lut[807] = 16'h085F;
    log_lut[808] = 16'h0888;
    log_lut[809] = 16'h08B1;
    log_lut[810] = 16'h08D9;
    log_lut[811] = 16'h0902;
    log_lut[812] = 16'h092A;
    log_lut[813] = 16'h0952;
    log_lut[814] = 16'h097A;
    log_lut[815] = 16'h09A3;
    log_lut[816] = 16'h09CB;
    log_lut[817] = 16'h09F3;
    log_lut[818] = 16'h0A1B;
    log_lut[819] = 16'h0A43;
    log_lut[820] = 16'h0A6B;
    log_lut[821] = 16'h0A93;
    log_lut[822] = 16'h0ABB;
    log_lut[823] = 16'h0AE3;
    log_lut[824] = 16'h0B0B;
    log_lut[825] = 16'h0B32;
    log_lut[826] = 16'h0B5A;
    log_lut[827] = 16'h0B82;
    log_lut[828] = 16'h0BA9;
    log_lut[829] = 16'h0BD1;
    log_lut[830] = 16'h0BF8;
    log_lut[831] = 16'h0C20;
    log_lut[832] = 16'h0C47;
    log_lut[833] = 16'h0C6F;
    log_lut[834] = 16'h0C96;
    log_lut[835] = 16'h0CBD;
    log_lut[836] = 16'h0CE4;
    log_lut[837] = 16'h0D0C;
    log_lut[838] = 16'h0D33;
    log_lut[839] = 16'h0D5A;
    log_lut[840] = 16'h0D81;
    log_lut[841] = 16'h0DA8;
    log_lut[842] = 16'h0DCF;
    log_lut[843] = 16'h0DF6;
    log_lut[844] = 16'h0E1C;
    log_lut[845] = 16'h0E43;
    log_lut[846] = 16'h0E6A;
    log_lut[847] = 16'h0E91;
    log_lut[848] = 16'h0EB7;
    log_lut[849] = 16'h0EDE;
    log_lut[850] = 16'h0F05;
    log_lut[851] = 16'h0F2B;
    log_lut[852] = 16'h0F52;
    log_lut[853] = 16'h0F78;
    log_lut[854] = 16'h0F9E;
    log_lut[855] = 16'h0FC5;
    log_lut[856] = 16'h0FEB;
    log_lut[857] = 16'h1011;
    log_lut[858] = 16'h1038;
    log_lut[859] = 16'h105E;
    log_lut[860] = 16'h1084;
    log_lut[861] = 16'h10AA;
    log_lut[862] = 16'h10D0;
    log_lut[863] = 16'h10F6;
    log_lut[864] = 16'h111C;
    log_lut[865] = 16'h1142;
    log_lut[866] = 16'h1168;
    log_lut[867] = 16'h118D;
    log_lut[868] = 16'h11B3;
    log_lut[869] = 16'h11D9;
    log_lut[870] = 16'h11FF;
    log_lut[871] = 16'h1224;
    log_lut[872] = 16'h124A;
    log_lut[873] = 16'h126F;
    log_lut[874] = 16'h1295;
    log_lut[875] = 16'h12BA;
    log_lut[876] = 16'h12E0;
    log_lut[877] = 16'h1305;
    log_lut[878] = 16'h132B;
    log_lut[879] = 16'h1350;
    log_lut[880] = 16'h1375;
    log_lut[881] = 16'h139A;
    log_lut[882] = 16'h13C0;
    log_lut[883] = 16'h13E5;
    log_lut[884] = 16'h140A;
    log_lut[885] = 16'h142F;
    log_lut[886] = 16'h1454;
    log_lut[887] = 16'h1479;
    log_lut[888] = 16'h149E;
    log_lut[889] = 16'h14C3;
    log_lut[890] = 16'h14E7;
    log_lut[891] = 16'h150C;
    log_lut[892] = 16'h1531;
    log_lut[893] = 16'h1556;
    log_lut[894] = 16'h157A;
    log_lut[895] = 16'h159F;
    log_lut[896] = 16'h15C4;
    log_lut[897] = 16'h15E8;
    log_lut[898] = 16'h160D;
    log_lut[899] = 16'h1631;
    log_lut[900] = 16'h1656;
    log_lut[901] = 16'h167A;
    log_lut[902] = 16'h169E;
    log_lut[903] = 16'h16C3;
    log_lut[904] = 16'h16E7;
    log_lut[905] = 16'h170B;
    log_lut[906] = 16'h172F;
    log_lut[907] = 16'h1753;
    log_lut[908] = 16'h1778;
    log_lut[909] = 16'h179C;
    log_lut[910] = 16'h17C0;
    log_lut[911] = 16'h17E4;
    log_lut[912] = 16'h1808;
    log_lut[913] = 16'h182B;
    log_lut[914] = 16'h184F;
    log_lut[915] = 16'h1873;
    log_lut[916] = 16'h1897;
    log_lut[917] = 16'h18BB;
    log_lut[918] = 16'h18DE;
    log_lut[919] = 16'h1902;
    log_lut[920] = 16'h1926;
    log_lut[921] = 16'h1949;
    log_lut[922] = 16'h196D;
    log_lut[923] = 16'h1990;
    log_lut[924] = 16'h19B4;
    log_lut[925] = 16'h19D7;
    log_lut[926] = 16'h19FB;
    log_lut[927] = 16'h1A1E;
    log_lut[928] = 16'h1A41;
    log_lut[929] = 16'h1A65;
    log_lut[930] = 16'h1A88;
    log_lut[931] = 16'h1AAB;
    log_lut[932] = 16'h1ACE;
    log_lut[933] = 16'h1AF2;
    log_lut[934] = 16'h1B15;
    log_lut[935] = 16'h1B38;
    log_lut[936] = 16'h1B5B;
    log_lut[937] = 16'h1B7E;
    log_lut[938] = 16'h1BA1;
    log_lut[939] = 16'h1BC4;
    log_lut[940] = 16'h1BE6;
    log_lut[941] = 16'h1C09;
    log_lut[942] = 16'h1C2C;
    log_lut[943] = 16'h1C4F;
    log_lut[944] = 16'h1C72;
    log_lut[945] = 16'h1C94;
    log_lut[946] = 16'h1CB7;
    log_lut[947] = 16'h1CDA;
    log_lut[948] = 16'h1CFC;
    log_lut[949] = 16'h1D1F;
    log_lut[950] = 16'h1D41;
    log_lut[951] = 16'h1D64;
    log_lut[952] = 16'h1D86;
    log_lut[953] = 16'h1DA9;
    log_lut[954] = 16'h1DCB;
    log_lut[955] = 16'h1DED;
    log_lut[956] = 16'h1E10;
    log_lut[957] = 16'h1E32;
    log_lut[958] = 16'h1E54;
    log_lut[959] = 16'h1E76;
    log_lut[960] = 16'h1E98;
    log_lut[961] = 16'h1EBA;
    log_lut[962] = 16'h1EDD;
    log_lut[963] = 16'h1EFF;
    log_lut[964] = 16'h1F21;
    log_lut[965] = 16'h1F43;
    log_lut[966] = 16'h1F64;
    log_lut[967] = 16'h1F86;
    log_lut[968] = 16'h1FA8;
    log_lut[969] = 16'h1FCA;
    log_lut[970] = 16'h1FEC;
    log_lut[971] = 16'h200E;
    log_lut[972] = 16'h202F;
    log_lut[973] = 16'h2051;
    log_lut[974] = 16'h2073;
    log_lut[975] = 16'h2094;
    log_lut[976] = 16'h20B6;
    log_lut[977] = 16'h20D8;
    log_lut[978] = 16'h20F9;
    log_lut[979] = 16'h211B;
    log_lut[980] = 16'h213C;
    log_lut[981] = 16'h215D;
    log_lut[982] = 16'h217F;
    log_lut[983] = 16'h21A0;
    log_lut[984] = 16'h21C1;
    log_lut[985] = 16'h21E3;
    log_lut[986] = 16'h2204;
    log_lut[987] = 16'h2225;
    log_lut[988] = 16'h2246;
    log_lut[989] = 16'h2268;
    log_lut[990] = 16'h2289;
    log_lut[991] = 16'h22AA;
    log_lut[992] = 16'h22CB;
    log_lut[993] = 16'h22EC;
    log_lut[994] = 16'h230D;
    log_lut[995] = 16'h232E;
    log_lut[996] = 16'h234F;
    log_lut[997] = 16'h2370;
    log_lut[998] = 16'h2390;
    log_lut[999] = 16'h23B1;
    log_lut[1000] = 16'h23D2;
    log_lut[1001] = 16'h23F3;
    log_lut[1002] = 16'h2413;
    log_lut[1003] = 16'h2434;
    log_lut[1004] = 16'h2455;
    log_lut[1005] = 16'h2475;
    log_lut[1006] = 16'h2496;
    log_lut[1007] = 16'h24B7;
    log_lut[1008] = 16'h24D7;
    log_lut[1009] = 16'h24F8;
    log_lut[1010] = 16'h2518;
    log_lut[1011] = 16'h2538;
    log_lut[1012] = 16'h2559;
    log_lut[1013] = 16'h2579;
    log_lut[1014] = 16'h259A;
    log_lut[1015] = 16'h25BA;
    log_lut[1016] = 16'h25DA;
    log_lut[1017] = 16'h25FA;
    log_lut[1018] = 16'h261B;
    log_lut[1019] = 16'h263B;
    log_lut[1020] = 16'h265B;
    log_lut[1021] = 16'h267B;
    log_lut[1022] = 16'h269B;
    log_lut[1023] = 16'h26BB;
end


endmodule
`endif