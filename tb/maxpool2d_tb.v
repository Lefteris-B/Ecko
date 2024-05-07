`timescale 1ns/1ps

module maxpool2d_tb;

  // Parameters
  parameter INPUT_WIDTH = 4;
  parameter INPUT_HEIGHT = 4;
  parameter INPUT_CHANNELS = 2;
  parameter KERNEL_WIDTH = 2;
  parameter KERNEL_HEIGHT = 2;
  parameter STRIDE = 2;

  // Inputs
  reg clk;
  reg rst_n;
  reg [INPUT_WIDTH*INPUT_HEIGHT*INPUT_CHANNELS-1:0] data_in;
  reg data_valid;

  // Outputs
  wire [(INPUT_WIDTH/STRIDE)*(INPUT_HEIGHT/STRIDE)*INPUT_CHANNELS-1:0] data_out;
  wire data_out_valid;

  // Instantiate the maxpool2d module
  maxpool2d #(
    .INPUT_WIDTH(INPUT_WIDTH),
    .INPUT_HEIGHT(INPUT_HEIGHT),
    .INPUT_CHANNELS(INPUT_CHANNELS),
    .KERNEL_WIDTH(KERNEL_WIDTH),
    .KERNEL_HEIGHT(KERNEL_HEIGHT),
    .STRIDE(STRIDE)
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
    data_in = {8'd1, 8'd2, 8'd3, 8'd4,
               8'd5, 8'd6, 8'd7, 8'd8,
               8'd9, 8'd10, 8'd11, 8'd12,
               8'd13, 8'd14, 8'd15, 8'd16,
               8'd17, 8'd18, 8'd19, 8'd20,
               8'd21, 8'd22, 8'd23, 8'd24,
               8'd25, 8'd26, 8'd27, 8'd28,
               8'd29, 8'd30, 8'd31, 8'd32};
    data_valid = 1;
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 1 failed: data_out_valid should be 1");
    assert(data_out == {8'd6, 8'd8, 8'd22, 8'd24}) else $error("Test case 1 failed: data_out mismatch");

    // Test case 2: Invalid input
    data_in = 0;
    data_valid = 1;
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 2 failed: data_out_valid should be 1");
    assert(data_out == 0) else $error("Test case 2 failed: data_out mismatch");

    // Add more test cases as needed

    #100;
    $display("Testbench completed");
    $finish;
  end

  // Assertions
  always @(posedge clk) begin
    if (data_out_valid) begin
      assert(data_out >= 0 && data_out < (1 << 8)) else $error("Output out of range");
    end
  end

endmodule