`timescale 1ns / 1ps

module tb_dct_module;

    // Parameters
    parameter Q_L = 11; // Number of fractional bits for logarithm output
    parameter Q_D = 4;  // Number of fractional bits for DCT output
    parameter N = 32;   // Size of the DCT input vector

    // Inputs
    reg clk;
    reg rst;
    reg signed [15:0] data_in;
    reg data_valid;

    // Outputs
    wire [639:0] dct_out; // 40 features * 16 bits = 640 bits
    wire dct_valid;

    // Instantiate the Unit Under Test (UUT)
    dct_module #(
        .Q_L(Q_L),
        .Q_D(Q_D),
        .N(N)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .dct_out(dct_out),
        .dct_valid(dct_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg signed [15:0] input_samples [0:N-1];
    reg [15:0] expected_output [0:39];
    reg [31:0] error_count;
    integer i, j;

    // Task to compute expected DCT output
    task compute_expected_dct_output;
        input signed [15:0] samples [0:N-1];
        output signed [15:0] output [0:39];
        integer i, j;
        real c;
        real sum;
        begin
            for (i = 0; i < 40; i = i + 1) begin
                sum = 0;
                for (j = 0; j < N; j = j + 1) begin
                    if (i == 0) begin
                        c = sqrt(1.0 / N);
                    end else begin
                        c = sqrt(2.0 / N) * cos((3.14159265358979 / N) * (j + 0.5) * i);
                    end
                    sum = sum + c * samples[j];
                end
                output[i] = sum * (1 << Q_D);
            end
        end
    endtask

    // Initial block to apply test cases and check results
    initial begin
        // Initialize inputs
        rst = 1;
        data_in = 0;
        data_valid = 0;
        error_count = 0;

        // Generate input samples
        for (i = 0; i < N; i = i + 1) begin
            input_samples[i] = i;
        end

        // Compute expected DCT output
        compute_expected_dct_output(input_samples, expected_output);

        // Release reset
        #20;
        rst = 0;

        // Apply input samples
        for (i = 0; i < N; i = i + 1) begin
            data_in = input_samples[i];
            data_valid = 1;
            #10;
            data_valid = 0;
            #10;
        end

        // Wait for the DCT processing to complete
        wait(dct_valid);

        // Verify DCT output
        for (i = 0; i < 40; i = i + 1) begin
            if (dct_out[i*16 +: 16] !== expected_output[i]) begin
                $display("ERROR: DCT Output index=%d, Expected Output=%d, Actual Output=%d", i, expected_output[i], dct_out[i*16 +: 16]);
                error_count = error_count + 1;
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
