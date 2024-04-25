// Goertzel Algorithm Module Testbench
module goertzel_tb;

    // Parameters
    parameter DATA_WIDTH  = 16;
    parameter FREQ_WIDTH  = 16;
    parameter SAMPLE_RATE = 16000;
    parameter NUM_FREQS   = 10;

    // Inputs
    reg                          clk;
    reg                          rst_n;
    reg signed [DATA_WIDTH-1:0]  sample_in;
    reg                          sample_valid;
    reg [FREQ_WIDTH-1:0]         freq_values [0:NUM_FREQS-1];

    // Outputs
    wire signed [DATA_WIDTH+1:0] mag_out [0:NUM_FREQS-1];
    wire                         mag_valid;

    // Instantiate the Goertzel algorithm module
    goertzel #(
        .DATA_WIDTH(DATA_WIDTH),
        .FREQ_WIDTH(FREQ_WIDTH),
        .SAMPLE_RATE(SAMPLE_RATE),
        .NUM_FREQS(NUM_FREQS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .sample_in(sample_in),
        .sample_valid(sample_valid),
        .freq_values(freq_values),
        .mag_out(mag_out),
        .mag_valid(mag_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Assertion for mag_valid signal
    always @(posedge clk) begin
        if (mag_valid) begin
            assert(sample_valid) else $error("mag_valid asserted without sample_valid");
        end
    end

    // Assertion for magnitude range
    always @(posedge clk) begin
        if (mag_valid) begin
            for (int i = 0; i < NUM_FREQS; i++) begin
                assert(mag_out[i] >= 0) else $error("Magnitude %0d is negative", i);
            end
        end
    end

    // Test cases
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        sample_in = 0;
        sample_valid = 0;

          // Dump waveforms
        $dumpfile("goertzel_tb.vcd");
        $dumpvars(0, goertzel_tb);

        // Apply reset
        #10 rst_n = 1;

        // Test case 1: Single frequency
        freq_values[0] = 1000;
        for (int i = 0; i < SAMPLE_RATE; i++) begin
            sample_in = $rtoi(32767 * $sin(2 * 3.14159 * freq_values[0] * i / SAMPLE_RATE));
            sample_valid = 1;
            #10;
        end
        sample_valid = 0;
        #10;

        // Test case 2: Multiple frequencies
        freq_values[0] = 500;
        freq_values[1] = 1500;
        freq_values[2] = 2500;
        for (int i = 0; i < SAMPLE_RATE; i++) begin
            sample_in = $rtoi(32767 * ($sin(2 * 3.14159 * freq_values[0] * i / SAMPLE_RATE) +
                                       $sin(2 * 3.14159 * freq_values[1] * i / SAMPLE_RATE) +
                                       $sin(2 * 3.14159 * freq_values[2] * i / SAMPLE_RATE)));
            sample_valid = 1;
            #10;
        end
        sample_valid = 0;
        #10;

        // Test case 3: No valid samples
        for (int i = 0; i < SAMPLE_RATE; i++) begin
            sample_in = 0;
            sample_valid = 0;
            #10;
        end

        // Finish the simulation
        $finish;
    end
  
endmodule