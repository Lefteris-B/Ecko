// Pre-emphasis Filter Testbench
module pre_emphasis_tb;

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter COEFF      = 16'h7D8F;  // 0.97 in Q15 format

    // Inputs
    reg                   clk;
    reg                   rst_n;
    reg [DATA_WIDTH-1:0]  audio_in;
    reg                   audio_valid;

    // Outputs
    wire [DATA_WIDTH-1:0] pre_emphasis_out;

    // Instantiate the pre-emphasis filter module
    pre_emphasis #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF(COEFF)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .audio_in(audio_in),
        .audio_valid(audio_valid),
        .pre_emphasis_out(pre_emphasis_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Assertion for output range
    always @(posedge clk) begin
        if (audio_valid) begin
            assert(pre_emphasis_out <= $signed(16'h7FFF) && pre_emphasis_out >= $signed(16'h8000))
                else $error("Output out of range: %0d", pre_emphasis_out);
        end
    end

    // Test cases
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        audio_in = 0;
        audio_valid = 0;

        // Apply reset
        #10 rst_n = 1;

        // Test case 1: Ramp input
        repeat(10) begin
            audio_in = audio_in + 100;
            audio_valid = 1;
            #10;
        end
        audio_valid = 0;
        #10;

        // Test case 2: Impulse input
        audio_in = 16'h7FFF;
        audio_valid = 1;
        #10;
        audio_in = 0;
        #10;
        audio_valid = 0;
        #50;

        // Test case 3: Sine wave input
        repeat(100) begin
            audio_in = $signed(16'h4000 * $sin(2 * 3.14159 * 10 * $time / 1000));
            audio_valid = 1;
            #10;
        end
        audio_valid = 0;
        #10;

        // Test case 4: Random input
        repeat(50) begin
            audio_in = $random;
            audio_valid = 1;
            #10;
        end
        audio_valid = 0;
        #10;

        // Finish the simulation
        $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("pre_emphasis_tb.vcd");
        $dumpvars(0, pre_emphasis_tb);
    end

endmodule