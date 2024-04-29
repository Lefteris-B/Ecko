`ifndef FULLY_CONNECTED_V
`define FULLY_CONNECTED_V

module fully_connected #(
    parameter INPUT_SIZE = 512,
    parameter OUTPUT_SIZE = 128,
    parameter ACTIVATION = "relu"
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE-1:0] data_in,
    input wire data_valid,
    output reg [OUTPUT_SIZE-1:0] data_out,
    output reg data_out_valid
);

// Declare weights and biases
reg [7:0] weights [0:OUTPUT_SIZE*INPUT_SIZE-1];
reg [7:0] biases [0:OUTPUT_SIZE-1];

// Declare internal signals
reg [15:0] mult_result [0:OUTPUT_SIZE-1];
reg [15:0] acc_result [0:OUTPUT_SIZE-1];
reg [15:0] relu_result [0:OUTPUT_SIZE-1];

// Fully connected layer operation
integer i, j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset internal signals and output
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            mult_result[i] <= 0;
            acc_result[i] <= 0;
            relu_result[i] <= 0;
        end
        data_out <= 0;
        data_out_valid <= 0;
    end else begin
        // Perform matrix multiplication
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            mult_result[i] = 0;
            for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                mult_result[i] = mult_result[i] + weights[i*INPUT_SIZE+j] * data_in[j];
            end
            acc_result[i] = mult_result[i] + biases[i];
        end

        // Apply activation function (ReLU)
        for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
            relu_result[i] <= (acc_result[i] > 0) ? acc_result[i] : 0;
        end

        // Assign output
        data_out <= {relu_result[127], relu_result[126], relu_result[125], relu_result[124],
                     relu_result[123], relu_result[122], relu_result[121], relu_result[120],
                     relu_result[119], relu_result[118], relu_result[117], relu_result[116],
                     relu_result[115], relu_result[114], relu_result[113], relu_result[112],
                     relu_result[111], relu_result[110], relu_result[109], relu_result[108],
                     relu_result[107], relu_result[106], relu_result[105], relu_result[104],
                     relu_result[103], relu_result[102], relu_result[101], relu_result[100],
                     relu_result[99], relu_result[98], relu_result[97], relu_result[96],
                     relu_result[95], relu_result[94], relu_result[93], relu_result[92],
                     relu_result[91], relu_result[90], relu_result[89], relu_result[88],
                     relu_result[87], relu_result[86], relu_result[85], relu_result[84],
                     relu_result[83], relu_result[82], relu_result[81], relu_result[80],
                     relu_result[79], relu_result[78], relu_result[77], relu_result[76],
                     relu_result[75], relu_result[74], relu_result[73], relu_result[72],
                     relu_result[71], relu_result[70], relu_result[69], relu_result[68],
                     relu_result[67], relu_result[66], relu_result[65], relu_result[64],
                     relu_result[63], relu_result[62], relu_result[61], relu_result[60],
                     relu_result[59], relu_result[58], relu_result[57], relu_result[56],
                     relu_result[55], relu_result[54], relu_result[53], relu_result[52],
                     relu_result[51], relu_result[50], relu_result[49], relu_result[48],
                     relu_result[47], relu_result[46], relu_result[45], relu_result[44],
                     relu_result[43], relu_result[42], relu_result[41], relu_result[40],
                     relu_result[39], relu_result[38], relu_result[37], relu_result[36],
                     relu_result[35], relu_result[34], relu_result[33], relu_result[32],
                     relu_result[31], relu_result[30], relu_result[29], relu_result[28],
                     relu_result[27], relu_result[26], relu_result[25], relu_result[24],
                     relu_result[23], relu_result[22], relu_result[21], relu_result[20],
                     relu_result[19], relu_result[18], relu_result[17], relu_result[16],
                     relu_result[15], relu_result[14], relu_result[13], relu_result[12],
                     relu_result[11], relu_result[10], relu_result[9], relu_result[8],
                     relu_result[7], relu_result[6], relu_result[5], relu_result[4],
                     relu_result[3], relu_result[2], relu_result[1], relu_result[0]};
        data_out_valid <= data_valid;
    end
end

endmodule
`endif