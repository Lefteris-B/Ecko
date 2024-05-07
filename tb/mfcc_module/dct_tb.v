// DCT Module Testbench
module dct_tb;

    // Parameters
    parameter DATA_WIDTH  = 16;
    parameter NUM_MFCC    = 13;
    parameter NUM_FILTERS = 26;

    // Inputs
    reg                          clk;
    reg                          rst_n;
    reg signed [DATA_WIDTH-1:0]  log_in [0:NUM_FILTERS-1];
    reg                          log_valid;

    // Outputs
    wire signed [DATA_WIDTH-1:0] mfcc_out [0:NUM_MFCC-1];
    wire                         mfcc_valid;

    // Instantiate the DCT module
    dct #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_MFCC(NUM_MFCC),
        .NUM_FILTERS(NUM_FILTERS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .log_in(log_in),
        .log_valid(log_valid),
        .mfcc_out(mfcc_out),
        .mfcc_valid(mfcc_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Assertion for mfcc_valid signal
    always @(posedge clk) begin
        if (mfcc_valid) begin
            assert(log_valid) else $error("mfcc_valid asserted without log_valid");
        end
    end

    // Assertion for MFCC output range
    always @(posedge clk) begin
        if (mfcc_valid) begin
            for (int i = 0; i < NUM_MFCC; i++) begin
                assert(mfcc_out[i] >= -32768 && mfcc_out[i] <= 32767)
                    else $error("MFCC output out of range");
            end
        end
    end

    // Test cases
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        log_valid = 0;

        // Apply reset
        #10 rst_n = 1;

        // Test case 1: Impulse input
        for (int i = 0; i < NUM_FILTERS; i++) begin
            log_in[i] = (i == NUM_FILTERS/2) ? 32767 : 0;
        end
        log_valid = 1;
        #10;
        log_valid = 0;
        #10;

        // Test case 2: Ramp input
        for (int i = 0; i < NUM_FILTERS; i++) begin
            log_in[i] = i * 1000;
        end
        log_valid = 1;
        #10;
        log_valid = 0;
        #10;

        // Test case 3: Sine wave input
        for (int i = 0; i < NUM_FILTERS; i++) begin
            log_in[i] = $rtoi(16384 * $sin(2 * 3.14159 * i / NUM_FILTERS));
        end
        log_valid = 1;
        #10;
        log_valid = 0;
        #10;

        // Test case 4: Random input
        for (int i = 0; i < NUM_FILTERS; i++) begin
            log_in[i] = $random % 65536 - 32768;
        end
        log_valid = 1;
        #10;
        log_valid = 0;
        #10;

        // Test case 5: No valid input
        log_valid = 0;
        #100;

        // Finish the simulation
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("dct_tb.vcd");
        $dumpvars(0, dct_tb);
    end

endmodule