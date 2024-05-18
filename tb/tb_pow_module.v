`timescale 1ns / 1ps

module tb_pow_module;
    // Parameters
    parameter Q = 15;

    // Inputs
    reg clk;
    reg rst;
    reg signed [31:0] data_in;
    reg data_valid;

    // Outputs
    wire signed [31:0] data_out;
    wire data_out_valid;

    // Instantiate the Unit Under Test (UUT)
    pow_module #(
        .Q(Q)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .data_out(data_out),
        .data_out_valid(data_out_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    reg signed [31:0] expected_data_out;
    reg [31:0] error_count;
    integer i;

    // Task to calculate expected output
    task calc_expected_output;
        input signed [31:0] input_val;
        output signed [31:0] output_val;
        begin
            output_val = (input_val * input_val) >>> Q;
        end
    endtask

    // Test case: Verify pow_module functionality
    initial begin
        // Initialize inputs
        rst = 1;
        data_in = 0;
        data_valid = 0;
        error_count = 0;

        // Release reset
        #20;
        rst = 0;

        // Apply test vectors
        for (i = -32768; i < 32768; i = i + 1024) begin
            #10;
            data_in = i <<< (30 - Q); // Scale input to Q30 format
            data_valid = 1;

            // Calculate expected output
            calc_expected_output(data_in, expected_data_out);

            // Wait for output to be valid
            @(posedge clk);
            #1;

            // Verify output
            if (data_out_valid) begin
                if (data_out !== expected_data_out) begin
                    $display("ERROR: Input=%d, Expected Output=%d, Actual Output=%d", data_in, expected_data_out, data_out);
                    error_count = error_count + 1;
                end
            end

            data_valid = 0;
            #10;
        end

        if (error_count == 0) begin
            $display("All test cases passed!");
        end else begin
            $display("%d test cases failed.", error_count);
        end

        $finish;
    end

endmodule
