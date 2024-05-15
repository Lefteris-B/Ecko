module fully_connected_psram #(
    parameter INPUT_SIZE = 320, // Adjust based on new dimensions
    parameter OUTPUT_SIZE = 64,
    parameter ACTIV_BITS = 16
) (
    input wire clk,
    input wire rst_n,
    input wire [INPUT_SIZE*ACTIV_BITS-1:0] data_in,
    input wire data_valid,
    output reg [OUTPUT_SIZE*ACTIV_BITS-1:0] data_out,
    output reg data_out_valid,
    
    // PSRAM controller
    inout EF_PSRAM_CTRL_V2 psram_ctrl,

    // Base addresses for weights and biases
    input wire [23:0] weight_base_addr,
    input wire [23:0] bias_base_addr
);

    // Internal signals for PSRAM controller
    reg [23:0] psram_addr;
    reg [31:0] psram_data_i;
    wire [31:0] psram_data_o;
    reg [2:0] psram_size;
    reg psram_start;
    wire psram_done;
    reg [7:0] psram_cmd;
    reg psram_rd_wr;
    reg psram_qspi;
    reg psram_qpi;
    reg psram_short_cmd;

    // Declare internal signals
    reg [ACTIV_BITS-1:0] weights [0:OUTPUT_SIZE-1][0:INPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:OUTPUT_SIZE-1];

    // Load weights and biases from PSRAM
    task load_weights_biases;
        integer i, j;
        begin
            for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin
                for (j = 0; j < INPUT_SIZE; j = j + 1) begin
                    // Read weight from PSRAM
                    psram_addr = weight_base_addr + (i * INPUT_SIZE + j) * (ACTIV_BITS / 8);
                    psram_cmd = 8'h03; // read command
                    psram_start = 1;
                    wait(psram_done);
                    psram_start = 0;
                    weights[i][j] = psram_data_o[ACTIV_BITS-1:0];
                end
                // Read bias from PSRAM
                psram_addr = bias_base_addr + i * (ACTIV_BITS / 8);
                psram_cmd = 8'h03; // read command
                psram_start = 1;
                wait(psram_done);
                psram_start = 0;
                biases[i] = psram_data_o[ACTIV_BITS-1:0];
            end
        end
    endtask

    // Fully connected layer operation
    integer i_fc, j_fc;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset internal signals and output
            data_out <= 0;
            data_out_valid <= 0;
        end else if (data_valid) begin
            for (i_fc = 0; i_fc < OUTPUT_SIZE; i_fc = i_fc + 1) begin
                // Initialize accumulation result with bias
                reg [2*ACTIV_BITS-1:0] acc_result = {{(2*ACTIV_BITS-ACTIV_BITS){1'b0}}, biases[i_fc]};
                for (j_fc = 0; j_fc < INPUT_SIZE; j_fc = j_fc + 1) begin
                    acc_result = acc_result + weights[i_fc][j_fc] * data_in[j_fc*ACTIV_BITS +: ACTIV_BITS];
                end
                // Apply ReLU activation
                reg [ACTIV_BITS-1:0] relu_result = (acc_result[2*ACTIV_BITS-1] == 0) ? acc_result[ACTIV_BITS-1:0] : 0;
                // Assign output
                data_out[i_fc*ACTIV_BITS +: ACTIV_BITS] <= relu_result;
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

    // Load weights and biases at startup
    initial begin
        load_weights_biases();
    end

endmodule
