`timescale 1ns / 1ps

module tb_log_module;

    // Parameters
    parameter Q_M = 15;
    parameter Q_L = 11;

    // Inputs
    reg clk;
    reg rst;
    reg signed [31:0] data_in;
    reg data_valid;

    // Outputs
    wire signed [15:0] log_out;
    wire log_valid;

    // Instantiate the Unit Under Test (UUT)
    log_module #(
        .Q_M(Q_M),
        .Q_L(Q_L)
    ) uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .log_out(log_out),
        .log_valid(log_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Testbench variables
    integer i;
    reg signed [31:0] test_data_in;
    reg signed [15:0] expected_log_out;
    reg [31:0] error_count;

    // Task to calculate expected log output
    task calc_expected_log_output;
        input signed [31:0] data_in;
        output signed [15:0] log_out;
        reg signed [INT_BITS-1:0] int_part;
        reg signed [FRAC_BITS-1:0] frac_part;
        reg signed [FRAC_BITS-1:0] frac_part_shifted;
        reg [$clog2(FRAC_BITS)-1:0] shift_count;
        integer i;
        begin
            int_part = data_in[31:FRAC_BITS];
            frac_part = data_in[FRAC_BITS-1:0];
            if (int_part > 0) begin
                frac_part_shifted = frac_part;
                log_out = 0;
                for (i = 0; i < FRAC_BITS; i = i + 1) begin
                    if (frac_part_shifted >= (1 << (FRAC_BITS - 1))) begin
                        frac_part_shifted = (frac_part_shifted << 1) - (1 << FRAC_BITS);
                        log_out = (log_out << 1) + 1;
                    end else begin
                        frac_part_shifted = frac_part_shifted << 1;
                        log_out = log_out << 1;
                    end
                end
                log_out = log_out[15:0] + (int_part << (Q_L - $clog2(INT_BITS)));
            end else begin
                log_out = {{1{frac_part[FRAC_BITS-1]}}, frac_part} >> (FRAC_BITS - Q_L);
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

        // Release reset
        #20;
        rst = 0;

        // Apply test vectors
        for (i = 1; i <= 10; i = i + 1) begin
            test_data_in = i << 16; // INT32 Q30 format
            data_in = test_data_in;
            data_valid = 1;

            // Calculate expected log output
            calc_expected_log_output(test_data_in, expected_log_out);

            // Wait for output to be valid
            @(posedge clk);
            #1;

            // Verify output
            if (log_valid) begin
                if (log_out !== expected_log_out) begin
                    $display("ERROR: Input=%d, Expected Log Output=%d, Actual Log Output=%d", test_data_in, expected_log_out, log_out);
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
