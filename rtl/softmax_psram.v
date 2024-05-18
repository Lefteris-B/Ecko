module softmax_psram #(
    parameter INPUT_SIZE = 10,
    parameter ACTIV_BITS = 8,
    parameter ADDR_WIDTH = 24
) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [ADDR_WIDTH-1:0] input_addr,
    input wire [ADDR_WIDTH-1:0] output_addr,
    output wire done,
    output wire psram_sck,
    output wire psram_ce_n,
    inout wire [3:0] psram_d,
    output wire [3:0] psram_douten
);

    // State definitions
    localparam IDLE = 0,
               LOAD_INPUT = 1,
               SOFTMAX = 2,
               STORE_OUTPUT = 3,
               DONE = 4;

    reg [2:0] state, next_state;
    reg [ADDR_WIDTH-1:0] addr;
    reg [31:0] psram_data_i;
    wire [31:0] psram_data_o;
    reg psram_start, psram_rd_wr;
    reg [2:0] psram_size;
    reg psram_qspi, psram_qpi, psram_short_cmd;
    wire psram_done;

    // Instantiate PSRAM controller
    EF_PSRAM_CTRL_V2 psram_ctrl (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .data_i(psram_data_i),
        .data_o(psram_data_o),
        .size(psram_size),
        .start(psram_start),
        .done(psram_done),
        .wait_states(4'b0000), // Adjust wait states if necessary
        .cmd(8'hEB), // Example command
        .rd_wr(psram_rd_wr),
        .qspi(psram_qspi),
        .qpi(psram_qpi),
        .short_cmd(psram_short_cmd),
        .sck(psram_sck),
        .ce_n(psram_ce_n),
        .din(psram_d),
        .dout(psram_d),
        .douten(psram_douten)
    );

    // Internal signals
    reg [ACTIV_BITS-1:0] input_data [0:INPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] output_data [0:INPUT_SIZE-1];
    reg [2*ACTIV_BITS-1:0] exp_lut [0:255];
    reg [2*ACTIV_BITS-1:0] sum_exp;
    reg [ACTIV_BITS-1:0] exp_values [0:INPUT_SIZE-1];
    integer i;
    reg [3:0] input_load_count;
    reg [3:0] output_store_count;
    reg data_valid;

    // Initialize LUT for exponential function
 initial begin
    exp_lut[0] = 16'd256;
    exp_lut[1] = 16'd258;
    exp_lut[2] = 16'd260;
    exp_lut[3] = 16'd262;
    exp_lut[4] = 16'd264;
    exp_lut[5] = 16'd266;
    exp_lut[6] = 16'd268;
    exp_lut[7] = 16'd270;
    exp_lut[8] = 16'd272;
    exp_lut[9] = 16'd274;
    exp_lut[10] = 16'd276;
    exp_lut[11] = 16'd278;
    exp_lut[12] = 16'd281;
    exp_lut[13] = 16'd283;
    exp_lut[14] = 16'd285;
    exp_lut[15] = 16'd287;
    exp_lut[16] = 16'd290;
    exp_lut[17] = 16'd292;
    exp_lut[18] = 16'd294;
    exp_lut[19] = 16'd296;
    exp_lut[20] = 16'd299;
    exp_lut[21] = 16'd301;
    exp_lut[22] = 16'd304;
    exp_lut[23] = 16'd306;
    exp_lut[24] = 16'd308;
    exp_lut[25] = 16'd311;
    exp_lut[26] = 16'd313;
    exp_lut[27] = 16'd316;
    exp_lut[28] = 16'd318;
    exp_lut[29] = 16'd321;
    exp_lut[30] = 16'd323;
    exp_lut[31] = 16'd326;
    exp_lut[32] = 16'd328;
    exp_lut[33] = 16'd331;
    exp_lut[34] = 16'd333;
    exp_lut[35] = 16'd336;
    exp_lut[36] = 16'd339;
    exp_lut[37] = 16'd341;
    exp_lut[38] = 16'd344;
    exp_lut[39] = 16'd347;
    exp_lut[40] = 16'd349;
    exp_lut[41] = 16'd352;
    exp_lut[42] = 16'd355;
    exp_lut[43] = 16'd358;
    exp_lut[44] = 16'd361;
    exp_lut[45] = 16'd363;
    exp_lut[46] = 16'd366;
    exp_lut[47] = 16'd369;
    exp_lut[48] = 16'd372;
    exp_lut[49] = 16'd375;
    exp_lut[50] = 16'd378;
    exp_lut[51] = 16'd381;
    exp_lut[52] = 16'd384;
    exp_lut[53] = 16'd387;
    exp_lut[54] = 16'd390;
    exp_lut[55] = 16'd393;
    exp_lut[56] = 16'd396;
    exp_lut[57] = 16'd399;
    exp_lut[58] = 16'd402;
    exp_lut[59] = 16'd405;
    exp_lut[60] = 16'd409;
    exp_lut[61] = 16'd412;
    exp_lut[62] = 16'd415;
    exp_lut[63] = 16'd418;
    exp_lut[64] = 16'd422;
    exp_lut[65] = 16'd425;
    exp_lut[66] = 16'd428;
    exp_lut[67] = 16'd432;
    exp_lut[68] = 16'd435;
    exp_lut[69] = 16'd438;
    exp_lut[70] = 16'd442;
    exp_lut[71] = 16'd445;
    exp_lut[72] = 16'd449;
    exp_lut[73] = 16'd452;
    exp_lut[74] = 16'd456;
    exp_lut[75] = 16'd459;
    exp_lut[76] = 16'd463;
    exp_lut[77] = 16'd467;
    exp_lut[78] = 16'd470;
    exp_lut[79] = 16'd474;
    exp_lut[80] = 16'd478;
    exp_lut[81] = 16'd482;
    exp_lut[82] = 16'd485;
    exp_lut[83] = 16'd489;
    exp_lut[84] = 16'd493;
    exp_lut[85] = 16'd497;
    exp_lut[86] = 16'd501;
    exp_lut[87] = 16'd505;
    exp_lut[88] = 16'd509;
    exp_lut[89] = 16'd513;
    exp_lut[90] = 16'd517;
    exp_lut[91] = 16'd521;
    exp_lut[92] = 16'd525;
    exp_lut[93] = 16'd529;
    exp_lut[94] = 16'd533;
    exp_lut[95] = 16'd537;
    exp_lut[96] = 16'd541;
    exp_lut[97] = 16'd546;
    exp_lut[98] = 16'd550;
    exp_lut[99] = 16'd554;
    exp_lut[100] = 16'd559;
    exp_lut[101] = 16'd563;
    exp_lut[102] = 16'd567;
    exp_lut[103] = 16'd572;
    exp_lut[104] = 16'd576;
    exp_lut[105] = 16'd581;
    exp_lut[106] = 16'd585;
    exp_lut[107] = 16'd590;
    exp_lut[108] = 16'd595;
    exp_lut[109] = 16'd599;
    exp_lut[110] = 16'd604;
    exp_lut[111] = 16'd609;
    exp_lut[112] = 16'd614;
    exp_lut[113] = 16'd618;
    exp_lut[114] = 16'd623;
    exp_lut[115] = 16'd628;
    exp_lut[116] = 16'd633;
    exp_lut[117] = 16'd638;
    exp_lut[118] = 16'd643;
    exp_lut[119] = 16'd648;
    exp_lut[120] = 16'd653;
    exp_lut[121] = 16'd658;
    exp_lut[122] = 16'd664;
    exp_lut[123] = 16'd669;
    exp_lut[124] = 16'd674;
    exp_lut[125] = 16'd679;
    exp_lut[126] = 16'd685;
    exp_lut[127] = 16'd690;
    exp_lut[128] = 16'd695;
    exp_lut[129] = 16'd701;
    exp_lut[130] = 16'd706;
    exp_lut[131] = 16'd712;
    exp_lut[132] = 16'd717;
    exp_lut[133] = 16'd723;
    exp_lut[134] = 16'd729;
    exp_lut[135] = 16'd734;
    exp_lut[136] = 16'd740;
    exp_lut[137] = 16'd746;
    exp_lut[138] = 16'd752;
    exp_lut[139] = 16'd758;
    exp_lut[140] = 16'd764;
    exp_lut[141] = 16'd770;
    exp_lut[142] = 16'd776;
    exp_lut[143] = 16'd782;
    exp_lut[144] = 16'd788;
    exp_lut[145] = 16'd794;
    exp_lut[146] = 16'd800;
    exp_lut[147] = 16'd807;
    exp_lut[148] = 16'd813;
    exp_lut[149] = 16'd819;
    exp_lut[150] = 16'd826;
    exp_lut[151] = 16'd832;
    exp_lut[152] = 16'd839;
    exp_lut[153] = 16'd845;
    exp_lut[154] = 16'd852;
    exp_lut[155] = 16'd859;
    exp_lut[156] = 16'd866;
    exp_lut[157] = 16'd872;
    exp_lut[158] = 16'd879;
    exp_lut[159] = 16'd886;
    exp_lut[160] = 16'd893;
    exp_lut[161] = 16'd900;
    exp_lut[162] = 16'd907;
    exp_lut[163] = 16'd914;
    exp_lut[164] = 16'd921;
    exp_lut[165] = 16'd929;
    exp_lut[166] = 16'd936;
    exp_lut[167] = 16'd943;
    exp_lut[168] = 16'd951;
    exp_lut[169] = 16'd958;
    exp_lut[170] = 16'd966;
    exp_lut[171] = 16'd973;
    exp_lut[172] = 16'd981;
    exp_lut[173] = 16'd989;
    exp_lut[174] = 16'd996;
    exp_lut[175] = 16'd1004;
    exp_lut[176] = 16'd1012;
    exp_lut[177] = 16'd1020;
    exp_lut[178] = 16'd1028;
    exp_lut[179] = 16'd1036;
    exp_lut[180] = 16'd1044;
    exp_lut[181] = 16'd1052;
    exp_lut[182] = 16'd1061;
    exp_lut[183] = 16'd1069;
    exp_lut[184] = 16'd1077;
    exp_lut[185] = 16'd1086;
    exp_lut[186] = 16'd1094;
    exp_lut[187] = 16'd1103;
    exp_lut[188] = 16'd1112;
    exp_lut[189] = 16'd1120;
    exp_lut[190] = 16'd1129;
    exp_lut[191] = 16'd1138;
    exp_lut[192] = 16'd1147;
    exp_lut[193] = 16'd1156;
    exp_lut[194] = 16'd1165;
    exp_lut[195] = 16'd1174;
    exp_lut[196] = 16'd1183;
    exp_lut[197] = 16'd1193;
    exp_lut[198] = 16'd1202;
    exp_lut[199] = 16'd1211;
    exp_lut[200] = 16'd1221;
    exp_lut[201] = 16'd1230;
    exp_lut[202] = 16'd1240;
    exp_lut[203] = 16'd1250;
    exp_lut[204] = 16'd1260;
    exp_lut[205] = 16'd1269;
    exp_lut[206] = 16'd1279;
    exp_lut[207] = 16'd1289;
    exp_lut[208] = 16'd1300;
    exp_lut[209] = 16'd1310;
    exp_lut[210] = 16'd1320;
    exp_lut[211] = 16'd1330;
    exp_lut[212] = 16'd1341;
    exp_lut[213] = 16'd1351;
    exp_lut[214] = 16'd1362;
    exp_lut[215] = 16'd1373;
    exp_lut[216] = 16'd1383;
    exp_lut[217] = 16'd1394;
    exp_lut[218] = 16'd1405;
    exp_lut[219] = 16'd1416;
    exp_lut[220] = 16'd1427;
    exp_lut[221] = 16'd1439;
    exp_lut[222] = 16'd1450;
    exp_lut[223] = 16'd1461;
    exp_lut[224] = 16'd1473;
    exp_lut[225] = 16'd1484;
    exp_lut[226] = 16'd1496;
    exp_lut[227] = 16'd1508;
    exp_lut[228] = 16'd1519;
    exp_lut[229] = 16'd1531;
    exp_lut[230] = 16'd1543;
    exp_lut[231] = 16'd1555;
    exp_lut[232] = 16'd1568;
    exp_lut[233] = 16'd1580;
    exp_lut[234] = 16'd1592;
    exp_lut[235] = 16'd1605;
    exp_lut[236] = 16'd1617;
    exp_lut[237] = 16'd1630;
    exp_lut[238] = 16'd1643;
    exp_lut[239] = 16'd1656;
    exp_lut[240] = 16'd1669;
    exp_lut[241] = 16'd1682;
    exp_lut[242] = 16'd1695;
    exp_lut[243] = 16'd1708;
    exp_lut[244] = 16'd1722;
    exp_lut[245] = 16'd1735;
    exp_lut[246] = 16'd1749;
    exp_lut[247] = 16'd1763;
    exp_lut[248] = 16'd1776;
    exp_lut[249] = 16'd1790;
    exp_lut[250] = 16'd1804;
    exp_lut[251] = 16'd1819;
    exp_lut[252] = 16'd1833;
    exp_lut[253] = 16'd1847;
    exp_lut[254] = 16'd1862;
    exp_lut[255] = 16'd1876;
end

    // State machine
    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = LOAD_INPUT;
            LOAD_INPUT: if (input_load_count == INPUT_SIZE) next_state = SOFTMAX;
            SOFTMAX: next_state = STORE_OUTPUT;
            STORE_OUTPUT: if (output_store_count == INPUT_SIZE) next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Control logic for PSRAM operations
    always @(posedge clk) begin
        if (rst) begin
            addr <= 0;
            psram_data_i <= 0;
            psram_start <= 0;
            psram_rd_wr <= 0;
            psram_size <= 3'b010; // 4 bytes
            psram_qspi <= 0;
            psram_qpi <= 0;
            psram_short_cmd <= 0;
            input_load_count <= 0;
            output_store_count <= 0;
            data_valid <= 0;
        end else begin
            psram_start <= 0;
            case (state)
                LOAD_INPUT: begin
                    if (!psram_start) begin
                        addr <= input_addr + input_load_count * 2; // Each input data is 2 bytes
                        psram_rd_wr <= 1; // Read operation
                        psram_start <= 1;
                    end else if (psram_done) begin
                        // Store data in input_data array
                        input_data[input_load_count] <= psram_data_o[ACTIV_BITS-1:0];
                        input_load_count <= input_load_count + 1;
                    end
                end

                STORE_OUTPUT: begin
                    if (!psram_start) begin
                        addr <= output_addr + output_store_count * 2; // Address to store results in PSRAM
                        psram_data_i <= {24'b0, output_data[output_store_count]}; // Write result
                        psram_rd_wr <= 0; // Write operation
                        psram_start <= 1;
                    end else if (psram_done) begin
                        output_store_count <= output_store_count + 1;
                    end
                end
            endcase
        end
    end

    // Softmax operation using LUT for exponentiation
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < INPUT_SIZE; i = i + 1) begin
                input_data[i] <= 0;
                output_data[i] <= 0;
            end
            sum_exp <= 0;
        end else if (state == SOFTMAX) begin
            // Compute the sum of exponentials using LUT
            sum_exp = 0;
            for (i = 0; i < INPUT_SIZE; i = i + 1) begin
                exp_values[i] = exp_lut[input_data[i]];
                sum_exp = sum_exp + exp_values[i];
            end

            // Compute softmax values
            for (i = 0; i < INPUT_SIZE; i = i + 1) begin
                output_data[i] = (exp_values[i] << ACTIV_BITS) / sum_exp[2*ACTIV_BITS-1:ACTIV_BITS];
            end
        end
    end

    assign done = (state == DONE);
endmodule
