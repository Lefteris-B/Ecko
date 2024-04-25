// Logarithm Module Testbench
module logarithm_tb;

    // Parameters
    parameter DATA_WIDTH  = 16;
    parameter LOG_WIDTH   = 8;
    parameter NUM_FILTERS = 26;

    // Inputs
    reg                             clk;
    reg                             rst_n;
    reg signed [DATA_WIDTH-1:0]     mel_in [0:NUM_FILTERS-1];
    reg                             mel_valid;

    // Outputs
    wire signed [LOG_WIDTH-1:0]     log_out [0:NUM_FILTERS-1];
    wire                            log_valid;

    // Instantiate the logarithm module
    logarithm #(
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_WIDTH(LOG_WIDTH),
        .NUM_FILTERS(NUM_FILTERS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .mel_in(mel_in),
        .mel_valid(mel_valid),
        .log_out(log_out),
        .log_valid(log_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Assertion for log_valid signal
    always @(posedge clk) begin
        if (log_valid) begin
            assert(mel_valid) else $error("log_valid asserted without mel_valid");
        end
    end

    // Assertion for logarithm output range
    always @(posedge clk) begin
        if (log_valid) begin
            for (int i = 0; i < NUM_FILTERS; i++) begin
                assert(log_out[i] >= -(1 << (LOG_WIDTH-1)) && log_out[i] < (1 << (LOG_WIDTH-1)))
                    else $error("Logarithm output out of range");
            end
        end
    end

    // Test cases
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        mel_valid = 0;

        // Apply reset
        #10 rst_n = 1;

        // Test case 1: Positive mel spectrum values
        for (int i = 0; i < NUM_FILTERS; i++) begin
            mel_in[i] = i + 1;
        end
        mel_valid = 1;
        #10;
        mel_valid = 0;
        #10;

        // Test case 2: Zero mel spectrum values
        for (int i = 0; i < NUM_FILTERS; i++) begin
            mel_in[i] = 0;
        end
        mel_valid = 1;
        #10;
        mel_valid = 0;
        #10;

        // Test case 3: Negative mel spectrum values
        for (int i = 0; i < NUM_FILTERS; i++) begin
            mel_in[i] = -i;
        end
        mel_valid = 1;
        #10;
        mel_valid = 0;
        #10;

        // Test case 4: Large mel spectrum values
        for (int i = 0; i < NUM_FILTERS; i++) begin
            mel_in[i] = 1000 + i;
        end
        mel_valid = 1;
        #10;
        mel_valid = 0;
        #10;

        // Test case 5: No valid input
        mel_valid = 0;
        #100;

        // Finish the simulation
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("logarithm_tb.vcd");
        $dumpvars(0, logarithm_tb);
    end

endmodule