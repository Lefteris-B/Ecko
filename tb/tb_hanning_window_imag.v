`timescale 1ns / 1ps

module tb_hanning_window_imag;

    // Parameters
    parameter N = 256;
    parameter Q = 15;
    parameter NF = 512;

    // Inputs
    reg clk;
    reg rst;
    reg [15:0] sample_in;
    reg sample_valid;

    // Outputs
    wire [15:0] sample_out;
    wire sample_out_valid;

    // Instantiate the Unit Under Test (UUT)
    hanning_window_imag uut (
        .clk(clk),
        .rst(rst),
        .sample_in(sample_in),
        .sample_valid(sample_valid),
        .sample_out(sample_out),
        .sample_out_valid(sample_out_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg [15:0] input_samples[N-1:0];
    reg [15:0] expected_output[NF-1:0];
    reg [31:0] error_count;
    integer i;

    // Task to generate input samples
    task generate_input_samples;
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                input_samples[i] = i;
            end
        end
    endtask

    // Task to calculate expected Hanning window output
    task calc_expected_output;
        input [15:0] samples[N-1:0];
        output [15:0] output_samples[NF-1:0];
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                output_samples[i] = (samples[i] * uut.hanning_coeff[i]) >>> Q;
            end
            for (i = N; i < NF; i = i + 1) begin
                output_samples[i] = 0;
            end
        end
    endtask

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        sample_in = 0;
        sample_valid = 0;
        error_count = 0;

        // Generate input samples
        generate_input_samples();

        // Calculate expected Hanning window output
        calc_expected_output(input_samples, expected_output);

        // Release reset
        #20;
        rst = 0;

        // Apply input samples
        for (i = 0; i < N; i = i + 1) begin
            sample_in = input_samples[i];
            sample_valid = 1;
            #10;
            sample_valid = 0;
            #10;
        end

        // Wait for the Hanning window processing to complete
        for (i = 0; i < NF; i = i + 1) begin
            @(posedge clk);
            #1;

            // Verify output
            if (sample_out_valid) begin
                if (sample_out !== expected_output[i]) begin
                    $display("ERROR: Index=%d, Expected Output=%d, Actual Output=%d", i, expected_output[i], sample_out);
                    error_count = error_count + 1;
                end
            end
        end

        if (error_count == 0) begin
            $display("All test cases passed!");
        end else begin
            $display("%d test cases failed.", error_count);
        end

        $finish;
    end

endmodule
