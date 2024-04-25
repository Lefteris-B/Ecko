// Mel Filterbank Testbench
module mel_filterbank_tb;

    // Parameters
    parameter DATA_WIDTH   = 16;
    parameter NUM_FILTERS  = 26;
    parameter FREQ_WIDTH   = 16;
    parameter SAMPLE_RATE  = 16000;
    parameter FFT_SIZE     = 256;

    // Inputs
    reg                           clk;
    reg                           rst_n;
    reg signed [DATA_WIDTH-1:0]   power_spectrum [0:FFT_SIZE-1];
    reg                           power_valid;

    // Outputs
    wire signed [DATA_WIDTH+$clog2(FFT_SIZE)-1:0] mel_out [0:NUM_FILTERS-1];
    wire                          mel_valid;

    // Instantiate the Mel Filterbank module
    mel_filterbank #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_FILTERS(NUM_FILTERS),
        .FREQ_WIDTH(FREQ_WIDTH),
        .SAMPLE_RATE(SAMPLE_RATE),
        .FFT_SIZE(FFT_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .power_spectrum(power_spectrum),
        .power_valid(power_valid),
        .mel_out(mel_out),
        .mel_valid(mel_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Assertion for mel_valid signal
    always @(posedge clk) begin
        if (mel_valid) begin
            assert(power_valid) else $error("mel_valid asserted without power_valid");
        end
    end

    // Assertion for mel spectrum range
    always @(posedge clk) begin
        if (mel_valid) begin
            for (int i = 0; i < NUM_FILTERS; i++) begin
                assert(mel_out[i] >= 0) else $error("Mel spectrum value is negative");
            end
        end
    end

    // Test cases
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        power_valid = 0;

        // Apply reset
        #10 rst_n = 1;

        // Test case 1: Impulse input
        for (int i = 0; i < FFT_SIZE; i++) begin
            power_spectrum[i] = (i == FFT_SIZE/2) ? 32767 : 0;
        end
        power_valid = 1;
        #10;
        power_valid = 0;
        #10;

        // Test case 2: Sine wave input
        for (int i = 0; i < FFT_SIZE; i++) begin
            power_spectrum[i] = $rtoi(32767 * $sin(2 * 3.14159 * i / FFT_SIZE));
        end
        power_valid = 1;
        #10;
        power_valid = 0;
        #10;

        // Test case 3: Ramp input
        for (int i = 0; i < FFT_SIZE; i++) begin
            power_spectrum[i] = i * 128;
        end
        power_valid = 1;
        #10;
        power_valid = 0;
        #10;

        // Test case 4: No valid input
        for (int i = 0; i < FFT_SIZE; i++) begin
            power_spectrum[i] = 0;
        end
        power_valid = 0;
        #100;

        // Finish the simulation
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("mel_filterbank_tb.vcd");
        $dumpvars(0, mel_filterbank_tb);
    end

endmodule