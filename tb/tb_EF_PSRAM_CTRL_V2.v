`timescale 1ns / 1ps

module tb_EF_PSRAM_CTRL_V2;

    // Parameters
    parameter ADDR_WIDTH = 24;
    parameter DATA_WIDTH = 32;

    // Inputs
    reg clk;
    reg rst;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] data_i;
    reg [2:0] size;
    reg start;
    reg [3:0] wait_states;
    reg [7:0] cmd;
    reg rd_wr;
    reg qspi;
    reg qpi;
    reg short_cmd;
    reg [3:0] din;

    // Outputs
    wire [DATA_WIDTH-1:0] data_o;
    wire done;
    wire sck;
    wire ce_n;
    wire [3:0] dout;
    wire [3:0] douten;

    // Instantiate the Unit Under Test (UUT)
    EF_PSRAM_CTRL_V2 uut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .data_i(data_i),
        .data_o(data_o),
        .size(size),
        .start(start),
        .done(done),
        .wait_states(wait_states),
        .cmd(cmd),
        .rd_wr(rd_wr),
        .qspi(qspi),
        .qpi(qpi),
        .short_cmd(short_cmd),
        .sck(sck),
        .ce_n(ce_n),
        .din(din),
        .dout(dout),
        .douten(douten)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg [31:0] psram_memory [0:2**ADDR_WIDTH-1];
    integer i;

    // Initialize PSRAM memory with known data
    initial begin
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
            psram_memory[i] = 32'hA5A5A5A5;
        end
    end

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        addr = 0;
        data_i = 0;
        size = 3'b010; // 4 bytes
        start = 0;
        wait_states = 4'd8;
        cmd = 8'hEB; // Example command
        rd_wr = 0; // Write operation
        qspi = 0;
        qpi = 0;
        short_cmd = 0;
        din = 4'b0;

        // Release reset
        #20;
        rst = 0;

        // Test Case 1: Write operation
        addr = 24'h000100;
        data_i = 32'hDEADBEEF;
        rd_wr = 0; // Write operation
        start = 1;
        #10;
        start = 0;

        // Wait for the operation to complete
        wait(done);

        // Verify the write operation
        assert(psram_memory[24'h000100] == 32'hDEADBEEF) else $fatal("ERROR: Write operation failed. Expected: 0xDEADBEEF, Got: 0x%h", psram_memory[24'h000100]);

        // Test Case 2: Read operation
        addr = 24'h000100;
        rd_wr = 1; // Read operation
        start = 1;
        #10;
        start = 0;

        // Wait for the operation to complete
        wait(done);

        // Verify the read operation
        assert(data_o == 32'hDEADBEEF) else $fatal("ERROR: Read operation failed. Expected: 0xDEADBEEF, Got: 0x%h", data_o);

        $display("All test cases passed!");
        $finish;
    end

    // PSRAM memory model
    always @(posedge clk) begin
        if (sck && !ce_n) begin
            if (rd_wr == 0) begin
                // Write operation
                psram_memory[addr] <= data_i;
            end else begin
                // Read operation
                din <= psram_memory[addr][3:0];
            end
        end
    end

endmodule
