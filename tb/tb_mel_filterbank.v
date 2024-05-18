`timescale 1ns / 1ps

module tb_mel_filterbank;

    // Parameters
    parameter Q = 15;
    parameter NUM_FILTERS = 40;
    parameter FILTER_SIZE = 23;
    parameter Q_M = 15;

    // Inputs
    reg clk;
    reg rst;
    reg signed [31:0] data_in;
    reg data_valid;

    // Outputs
    wire signed [31:0] mel_out;
    wire mel_valid;

    // Instantiate the Unit Under Test (UUT)
    mel_filterbank #(
        .Q(Q),
        .NUM_FILTERS(NUM_FILTERS),
        .FILTER_SIZE(FILTER_SIZE),
        .Q_M(Q_M)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .mel_out(mel_out),
        .mel_valid(mel_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg signed [31:0] periodogram_samples[FILTER_SIZE-1:0];
    reg signed [15:0] expected_coeffs[FILTER_SIZE-1:0];
    reg signed [47:0] expected_accum;
    reg signed [31:0] expected_mel_out;
    reg [31:0] error_count;
    integer i, j;

    // Task to calculate the expected Mel filter output
    task calc_expected_mel_output;
        input signed [31:0] periodogram[FILTER_SIZE-1:0];
        output signed [31:0] mel_out;
        reg signed [47:0] accum;
        integer i;
        begin
            accum = 0;
            for (i = 0; i < FILTER_SIZE; i = i + 1) begin
                accum = accum + ({{16{periodogram[i][15]}}, periodogram[i]} * {{16{expected_coeffs[i][15]}}, expected_coeffs[i]});
            end
            mel_out = accum[31:0] >>> (Q + Q_M);
        end
    endtask

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        data_in = 0;
        data_valid = 0;
        error_count = 0;

        // Generate test periodogram samples and coefficients
        for (i = 0; i < FILTER_SIZE; i = i + 1) begin
            periodogram_samples[i] = i << Q; // Q30 format
            expected_coeffs[i] = 16'h4000; // Q15 format, example coefficient
        end

        // Calculate the expected Mel filter output
        calc_expected_mel_output(periodogram_samples, expected_mel_out);

        // Release reset
        #20;
        rst = 0;

        // Send periodogram samples to the UUT
        for (i = 0; i < FILTER_SIZE; i = i + 1) begin
            data_in = periodogram_samples[i];
            data_valid = 1;
            #10;
            data_valid = 0;
            #10;
        end

        // Wait for Mel filter output to be valid and check the output
        wait(mel_valid);

        if (mel_out !== expected_mel_out) begin
            $display("ERROR: Expected Mel output=%d, Actual Mel output=%d", expected_mel_out, mel_out);
            error_count = error_count + 1;
        end else begin
            $display("Mel output matched expected value.");
        end

        if (error_count == 0) begin
            $display("All test cases passed!");
        end else begin
            $display("%d test cases failed.", error_count);
        end

        $finish;
    end

endmodule
