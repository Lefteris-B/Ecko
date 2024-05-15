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
    
    // PSRAM interface signals
    output wire psram_sck,
    output wire psram_ce_n,
    inout wire [3:0] psram_d,
    output wire [3:0] psram_douten,

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

    // Instantiate PSRAM controller
    EF_PSRAM_CTRL_V2 psram_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .addr(psram_addr),
        .data_i(psram_data_i),
        .data_o(psram_data_o),
        .size(psram_size),
        .start(psram_start),
        .done(psram_done),
        .wait_states(8'b0),
        .cmd(psram_cmd),
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

    // Declare internal signals
    reg [ACTIV_BITS-1:0] weights [0:OUTPUT_SIZE-1][0:INPUT_SIZE-1];
    reg [ACTIV_BITS-1:0] biases [0:OUTPUT_SIZE-1];
    reg [2*ACTIV_BITS-1:0] acc_result;
    reg [ACTIV_BITS-1:0] relu_result;

    // State machine for loading weights and biases
    reg [3:0] state;
    integer i, j;
    reg [23:0] current_addr;

    localparam IDLE = 4'b0000,
               LOAD_WEIGHT = 4'b0001,
               WAIT_WEIGHT = 4'b0010,
               LOAD_BIAS = 4'b0011,
               WAIT_BIAS = 4'b0100,
               DONE = 4'b0101;

    // State transitions and output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            psram_start <= 0;
            psram_addr <= 0;
            psram_cmd <= 8'h03; // read command
            psram_rd_wr <= 0; // read operation
            current_addr <= 0;
            i <= 0;
            j <= 0;
        end else begin
            case (state)
                IDLE: begin
                    state <= LOAD_WEIGHT;
                end
                LOAD_WEIGHT: begin
                    psram_start <= 1;
                    psram_addr <= weight_base_addr + (i * INPUT_SIZE + j) * (ACTIV_BITS / 8);
                    state <= WAIT_WEIGHT;
                end
                WAIT_WEIGHT: begin
                    psram_start <= 0;
                    if (psram_done) begin
                        weights[i][j] <= psram_data_o[ACTIV_BITS-1:0];
                        j <= j + 1;
                        if (j == INPUT_SIZE - 1) begin
                            j <= 0;
                            i <= i + 1;
                            if (i == OUTPUT_SIZE - 1) begin
                                state <= LOAD_BIAS;
                            end
                        end
                    end
                end
                LOAD_BIAS: begin
                    psram_start <= 1;
                    psram_addr <= bias_base_addr + i * (ACTIV_BITS / 8);
                    state <= WAIT_BIAS;
                end
                WAIT_BIAS: begin
                    psram_start <= 0;
                    if (psram_done) begin
                        biases[i] <= psram_data_o[ACTIV_BITS-1:0];
                        i <= i + 1;
                        if (i == OUTPUT_SIZE - 1) begin
                            state <= DONE;
                        end
                    end
                end
                DONE: begin
                    // Do nothing, stay in DONE state
                end
            endcase
        end
    end

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
                acc_result = {{(2*ACTIV_BITS-ACTIV_BITS){1'b0}}, biases[i_fc]};
                for (j_fc = 0; j_fc < INPUT_SIZE; j_fc = j_fc + 1) begin
                    acc_result = acc_result + weights[i_fc][j_fc] * data_in[j_fc*ACTIV_BITS +: ACTIV_BITS];
                end
                // Apply ReLU activation
                relu_result = (acc_result[2*ACTIV_BITS-1] == 0) ? acc_result[ACTIV_BITS-1:0] : 0;
                // Assign output
                data_out[i_fc*ACTIV_BITS +: ACTIV_BITS] <= relu_result;
            end
            data_out_valid <= 1;
        end else begin
            data_out_valid <= 0;
        end
    end

endmodule

