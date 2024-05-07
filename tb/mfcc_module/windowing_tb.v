// Windowing Module Testbench
module windowing_tb;

    // Parameters
    parameter DATA_WIDTH  = 16;
    parameter FRAME_SIZE  = 256;
    parameter WINDOW_TYPE = "hamming";

    // Inputs
    reg                   clk;
    reg                   rst_n;
    reg [DATA_WIDTH-1:0]  frame_data [0:FRAME_SIZE-1];
    reg                   frame_valid;

    // Outputs
    wire [DATA_WIDTH-1:0] windowed_data [0:FRAME_SIZE-1];
    wire                  windowed_valid;

    // Instantiate the windowing module
    windowing #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAME_SIZE(FRAME_SIZE),
        .WINDOW_TYPE(WINDOW_TYPE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .frame_data(frame_data),
        .frame_valid(frame_valid),
        .windowed_data(windowed_data),
        .windowed_valid(windowed_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Assertion for windowed_valid signal
    always @(posedge clk) begin
        if (windowed_valid) begin
            assert(frame_valid) else $error("windowed_valid asserted without frame_valid");
        end
    end

    // Assertion for windowed data range
    always @(posedge clk) begin
        if (windowed_valid) begin
            for (int i = 0; i < FRAME_SIZE; i++) begin
                assert(windowed_data[i] <= $signed(16'h7FFF) && windowed_data[i] >= $signed(16'h8000))
                    else $error("Windowed data out of range at index %0d: %0d", i, windowed_data[i]);
            end
        end
    end

    // Test cases
    initial begin
        // Initialize inputs
        clk = 0;
        rst_n = 0;
        frame_valid = 0;
      	    // Dump waveforms
        $dumpfile("windowing_tb.vcd");
        $dumpvars(0, windowing_tb);

        // Apply reset
        #10 rst_n = 1;

        // Test case 1: Ramp input
        for (int i = 0; i < FRAME_SIZE; i++) begin
            frame_data[i] = i;
        end
        frame_valid = 1;
        #10;
        frame_valid = 0;
        #10;

        // Test case 2: Sine wave input
        for (int i = 0; i < FRAME_SIZE; i++) begin
            frame_data[i] = $rtoi(16384 * $sin(2 * 3.14159 * i / FRAME_SIZE));
        end
        frame_valid = 1;
        #10;
        frame_valid = 0;
        #10;

        // Test case 3: Constant input
        for (int i = 0; i < FRAME_SIZE; i++) begin
            frame_data[i] = 16'h4000;
        end
        frame_valid = 1;
        #10;
        frame_valid = 0;
        #10;

        // Test case 4: Impulse input
        for (int i = 0; i < FRAME_SIZE; i++) begin
            frame_data[i] = (i == FRAME_SIZE/2) ? 16'h7FFF : 0;
        end
        frame_valid = 1;
        #10;
        frame_valid = 0;
        #10;

        // Finish the simulation
        $finish;
    end

endmodule