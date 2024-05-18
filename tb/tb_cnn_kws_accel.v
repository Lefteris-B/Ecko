`timescale 1ns / 1ps

module tb_cnn_kws_accel;

    // Parameters
    parameter INPUT_WIDTH = 40;
    parameter INPUT_HEIGHT = 1;
    parameter INPUT_CHANNELS = 1;
    parameter KERNEL_SIZE = 3;
    parameter NUM_FILTERS = 8;
    parameter PADDING = 1;
    parameter ACTIV_BITS = 16;
    parameter ADDR_WIDTH = 24;

    // Inputs
    reg clk;
    reg rst;
    reg start;
    reg [15:0] audio_sample;
    reg sample_valid;

    // Outputs
    wire done;
    wire [37:0] io_out;
    wire [37:0] io_oeb;

    // PSRAM interface signals
    wire psram_sck;
    wire psram_ce_n;
    wire [3:0] psram_d;
    wire [3:0] psram_douten;

    // Instantiate the Unit Under Test (UUT)
    cnn_kws_accel uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .audio_sample(audio_sample),
        .sample_valid(sample_valid),
        .done(done),
        .psram_sck(psram_sck),
        .psram_ce_n(psram_ce_n),
        .psram_d(psram_d),
        .psram_douten(psram_douten),
        .io_out(io_out),
        .io_oeb(io_oeb)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Initialize test vectors
    initial begin
        // Initialize Inputs
        rst = 1;
        start = 0;
        audio_sample = 0;
        sample_valid = 0;

        // Wait for global reset
        #20;
        rst = 0;

        // Apply test stimulus
        #10;
        start = 1;
        #10;
        start = 0;

        // Provide audio sample input
        #10;
        sample_valid = 1;
        audio_sample = 16'h1234;
        #10;
        sample_valid = 0;

        // Wait for done signal
        wait(done);
        $display("Test completed successfully");
        $finish;
    end

    // PSRAM memory model
    reg [31:0] psram_memory [0:2**ADDR_WIDTH-1];

    initial begin
        for (integer i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
            psram_memory[i] = 32'hA5A5A5A5;
        end
    end

    // Handle PSRAM read/write operations
    always @(posedge clk) begin
        if (!psram_ce_n) begin
            if (psram_douten) begin
                // Write operation
                psram_memory[psram_memory_address(psram_douten)] <= {28'b0, psram_d};
            end else begin
                // Read operation
                psram_d <= psram_memory[psram_memory_address(psram_douten)][3:0];
            end
        end
    end

    // PSRAM memory address calculation function
    function [ADDR_WIDTH-1:0] psram_memory_address(input [3:0] douten);
        psram_memory_address = uut.state == uut.CONV1 ? uut.conv1_weight_base_addr :
                               uut.state == uut.CONV2 ? uut.conv2_weight_base_addr :
                               uut.state == uut.FC1   ? uut.fc1_weight_base_addr :
                               uut.state == uut.FC2   ? uut.fc2_weight_base_addr :
                               uut.state == uut.MAXPOOL ? uut.maxpool_input_addr :
                               uut.state == uut.SOFTMAX ? uut.softmax_input_addr : 0;
    endfunction

    // Assertions for each state transition
    always @(posedge clk) begin
        if (rst) begin
            // Assertions are skipped during reset
        end else begin
            case (uut.state)
                uut.IDLE: begin
                    assert(!done) else $fatal("ERROR: Done signal should be low in IDLE state.");
                end
                uut.MFCC: begin
                    assert(sample_valid) else $fatal("ERROR: Sample valid signal should be high in MFCC state.");
                end
                uut.CONV1: begin
                    assert(uut.conv1_psram_sck) else $fatal("ERROR: PSRAM clock should be active in CONV1 state.");
                end
                uut.CONV2: begin
                    assert(uut.conv2_psram_sck) else $fatal("ERROR: PSRAM clock should be active in CONV2 state.");
                end
                uut.FC1: begin
                    assert(uut.fc1_psram_sck) else $fatal("ERROR: PSRAM clock should be active in FC1 state.");
                end
                uut.FC2: begin
                    assert(uut.fc2_psram_sck) else $fatal("ERROR: PSRAM clock should be active in FC2 state.");
                end
                uut.MAXPOOL: begin
                    assert(uut.maxpool_psram_sck) else $fatal("ERROR: PSRAM clock should be active in MAXPOOL state.");
                end
                uut.SOFTMAX: begin
                    assert(uut.softmax_psram_sck) else $fatal("ERROR: PSRAM clock should be active in SOFTMAX state.");
                end
                default: begin
                    assert(0) else $fatal("ERROR: Unknown state.");
                end
            endcase
        end
    end
endmodule
