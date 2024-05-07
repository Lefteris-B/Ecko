// Framing Module Testbench
module framing_tb;

    // Parameters
    parameter DATA_WIDTH   = 16;
    parameter FRAME_SIZE   = 256;
    parameter FRAME_STRIDE = 128;

    // Inputs
    reg                  clk;
    reg                  rst_n;
    reg [DATA_WIDTH-1:0] audio_in;
    reg                  audio_valid;

    // Outputs
    wire [DATA_WIDTH-1:0] frame_data [0:FRAME_SIZE-1];
    wire                  frame_valid;

    // Instantiate the framing module
    framing #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAME_SIZE(FRAME_SIZE),
        .FRAME_STRIDE(FRAME_STRIDE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .audio_in(audio_in),
        .audio_valid(audio_valid),
        .frame_data(frame_data),
        .frame_valid(frame_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Assertion for frame_valid signal
    always @(posedge clk) begin
        if (frame_valid) begin
            assert(audio_valid) else $error("frame_valid asserted without audio_valid");
        end
    end

    // Assertion for frame data consistency
    always @(posedge clk) begin
        if (frame_valid) begin
            for (int i = 0; i < FRAME_SIZE; i++) begin
                assert(frame_data[i] === dut.buffer[(dut.read_ptr + i) % FRAME_SIZE])
                    else $error("Frame data mismatch at index %0d", i);
            end
        end
    end

    // Test cases
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        audio_in = 0;
        audio_valid = 0;

        
    // Dump waveforms
    
        $dumpfile("framing_tb.vcd");
        $dumpvars(0, framing_tb);// Apply reset
        #10 rst_n = 1;

        // Test case 1: Continuous valid audio samples
        for (int i = 0; i < FRAME_SIZE * 4; i++) begin
            audio_in = i % 65536;
            audio_valid = 1;
            #10;
        end
        audio_valid = 0;

        // Test case 2: Intermittent valid audio samples
        for (int i = 0; i < FRAME_SIZE * 2; i++) begin
            audio_in = i % 65536;
            audio_valid = i % 4 < 2;
            #10;
        end
        audio_valid = 0;

        // Test case 3: No valid audio samples
        #100;

        // Test case 4: Single valid audio sample
        audio_in = 12345;
        audio_valid = 1;
        #10;
        audio_valid = 0;
        #100;

        // Finish the simulation
        $finish;
    end

  

endmodule