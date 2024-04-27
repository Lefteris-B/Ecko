`timescale 1ns/1ps

module softmax_tb;

  // Parameters
  parameter INPUT_SIZE = 128;
  parameter OUTPUT_SIZE = 2;
  parameter LUT_SIZE = 256;
  parameter LUT_WIDTH = 16;

  // Inputs
  reg clk;
  reg rst_n;
  reg [INPUT_SIZE-1:0] data_in;
  reg data_valid;

  // Outputs
  wire [OUTPUT_SIZE-1:0] data_out;
  wire data_out_valid;

  // Instantiate the softmax module
  softmax #(
    .INPUT_SIZE(INPUT_SIZE),
    .OUTPUT_SIZE(OUTPUT_SIZE),
    .LUT_SIZE(LUT_SIZE),
    .LUT_WIDTH(LUT_WIDTH)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_valid(data_valid),
    .data_out(data_out),
    .data_out_valid(data_out_valid)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Stimulus generation
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 0;
    data_valid = 0;

    // Reset assertion
    #10 rst_n = 1;
    @(posedge clk);

    // Test case 1: Valid input
    data_in = {16'd10, 16'd20, 16'd30, 16'd40};
    data_valid = 1;
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 1 failed: data_out_valid should be 1");

    // Test case 2: Invalid input
    data_in = {16'd0, 16'd0, 16'd0, 16'd0};
    data_valid = 1;
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 2 failed: data_out_valid should be 1");

    // Test case 3: Consecutive inputs
    data_in = {16'd5, 16'd10, 16'd15, 16'd20};
    data_valid = 1;
    @(posedge clk);
    data_in = {16'd25, 16'd30, 16'd35, 16'd40};
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 3 failed: data_out_valid should be 1");

    // Add more test cases as needed

    #100;
    $display("Testbench completed");
    $finish;
  end

  // Assertions
  always @(posedge clk) begin
    if (data_out_valid) begin
      assert(data_out >= 0 && data_out < OUTPUT_SIZE) else $error("Output out of range");
    end
  end

endmodule