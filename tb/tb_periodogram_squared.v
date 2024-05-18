`timescale 1ns / 1ps

module tb_periodogram_squared;

    // Parameters
    localparam NF = 512;
    localparam Q = 15;

    // Inputs
    reg clk;
    reg rst;
    reg signed [15:0] sample_in_real;
    reg signed [15:0] sample_in_imag;
    reg sample_valid;

    // Outputs
    wire signed [31:0] periodogram_out;
    wire periodogram_valid;

    // Instantiate the Unit Under Test (UUT)
    periodogram_squared uut (
        .clk(clk),
        .rst(rst),
        .sample_in_real(sample_in_real),
        .sample_in_imag(sample_in_imag),
        .sample_valid(sample_valid),
        .periodogram_out(periodogram_out),
        .periodogram_valid(periodogram_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    integer i;
    reg signed [15:0] test_real[NF-1:0];
    reg signed [15:0] test_imag[NF-1:0];
    reg signed [31:0] expected_out[NF-1:0];
    reg [31:0] error_count;

    // Task to calculate expected periodogram output
    task calc_expected_output;
        input signed [15:0] real_in[NF-1:0];
        input signed [15:0] imag_in[NF-1:0];
        output signed [31:0] periodogram[NF-1:0];
        integer i;
        begin
            for (i = 0; i < NF; i = i + 1) begin
                periodogram[i] = ((real_in[i] * real_in[i]) + (imag_in[i] * imag_in[i])) >>> Q;
            end
        end
    endtask

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        sample_in_real = 0;
        sample_in_imag = 0;
        sample_valid = 0;
        error_count = 0;

        // Release reset
        #20;
        rst = 0;

        // Apply test vectors
        for (i = 0; i < NF; i = i + 1) begin
            test_real[i] = i;
            test_imag[i] = -i;
        end

        // Calculate expected outputs
        calc_expected_output(test_real, test_imag, expected_out);

        // Send samples to the UUT
        for (i = 0; i < NF; i = i + 1) begin
            sample_in_real = test_real[i];
            sample_in_imag = test_imag[i];
            sample_valid = 1;
            #10;
            sample_valid = 0;
            #10;
        end

        // Wait for periodogram to be valid and check outputs
        i = 0;
        while (i < NF) begin
            @(posedge clk);
            if (periodogram_valid) begin
                if (periodogram_out !== expected_out[i]) begin
                    $display("ERROR: Index=%d, Expected Output=%d, Actual Output=%d", i, expected_out[i], periodogram_out);
                    error_count = error_count + 1;
                end
                i = i + 1;
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
