`timescale 1ns/1ps

module cnn_kws_accel_tb;

  // Parameters
  parameter INPUT_WIDTH = 32;
  parameter OUTPUT_SIZE = 2;

  // Inputs
  reg clk;
  reg rst_n;
  reg [INPUT_WIDTH-1:0] mfcc_in;
  reg mfcc_valid;

  // Outputs
  wire [OUTPUT_SIZE-1:0] keyword_class;
  wire keyword_detected;

  // Instantiate the cnn_kws_accel module
  cnn_kws_accel #(
    .INPUT_WIDTH(INPUT_WIDTH),
    .OUTPUT_SIZE(OUTPUT_SIZE)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .mfcc_in(mfcc_in),
    .mfcc_valid(mfcc_valid),
    .keyword_class(keyword_class),
    .keyword_detected(keyword_detected)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Stimulus generation
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    mfcc_in = 0;
    mfcc_valid = 0;

    // Reset assertion
    #10 rst_n = 1;
    @(posedge clk);

    // Test case 1: Valid input sequence for keyword 1
    mfcc_in = 32'h1234_5678;
    mfcc_valid = 1;
    @(posedge clk);
    mfcc_in = 32'h2345_6789;
    @(posedge clk);
    mfcc_in = 32'h3456_789A;
    @(posedge clk);
    mfcc_in = 32'h4567_89AB;
    @(posedge clk);
    mfcc_valid = 0;
    @(posedge clk);
    #10;
    assert(keyword_detected == 1) else $error("Test case 1 failed: keyword_detected should be 1");
    assert(keyword_class == 2'b01) else $error("Test case 1 failed: keyword_class mismatch");

    // Test case 2: Valid input sequence for keyword 2
    mfcc_in = 32'hABCD_EF01;
    mfcc_valid = 1;
    @(posedge clk);
    mfcc_in = 32'hBCDE_F012;
    @(posedge clk);
    mfcc_in = 32'hCDEF_0123;
    @(posedge clk);
    mfcc_in = 32'hDEF0_1234;
    @(posedge clk);
    mfcc_valid = 0;
    @(posedge clk);
    #10;
    assert(keyword_detected == 1) else $error("Test case 2 failed: keyword_detected should be 1");
    assert(keyword_class == 2'b10) else $error("Test case 2 failed: keyword_class mismatch");

    // Test case 3: Invalid input sequence
    mfcc_in = 32'h1111_1111;
    mfcc_valid = 1;
    @(posedge clk);
    mfcc_in = 32'h2222_2222;
    @(posedge clk);
    mfcc_in = 32'h3333_3333;
    @(posedge clk);
    mfcc_in = 32'h4444_4444;
    @(posedge clk);
    mfcc_valid = 0;
    @(posedge clk);
    #10;
    assert(keyword_detected == 0) else $error("Test case 3 failed: keyword_detected should be 0");

    // Add more test cases as needed

    #100;
    $display("Testbench completed");
    $finish;
  end

  // Assertions
  always @(posedge clk) begin
    if (keyword_detected) begin
      assert(keyword_class >= 0 && keyword_class < OUTPUT_SIZE) else $error("Keyword class out of range");
    end
  end

endmodule