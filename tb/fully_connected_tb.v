`timescale 1ns/1ps

module fully_connected_tb;

  // Parameters
  parameter INPUT_SIZE = 512;
  parameter OUTPUT_SIZE = 128;
  parameter ACTIVATION = "relu";

  // Inputs
  reg clk;
  reg rst_n;
  reg [INPUT_SIZE-1:0] data_in;
  reg data_valid;

  // Outputs
  wire [OUTPUT_SIZE-1:0] data_out;
  wire data_out_valid;

  // Instantiate the fully_connected module
  fully_connected #(
    .INPUT_SIZE(INPUT_SIZE),
    .OUTPUT_SIZE(OUTPUT_SIZE),
    .ACTIVATION(ACTIVATION)
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
    data_in = {16'd1, 16'd2, 16'd3, 16'd4, 16'd5, 16'd6, 16'd7, 16'd8,
               16'd9, 16'd10, 16'd11, 16'd12, 16'd13, 16'd14, 16'd15, 16'd16,
               16'd17, 16'd18, 16'd19, 16'd20, 16'd21, 16'd22, 16'd23, 16'd24,
               16'd25, 16'd26, 16'd27, 16'd28, 16'd29, 16'd30, 16'd31, 16'd32};
    data_valid = 1;
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 1 failed: data_out_valid should be 1");
    // Add assertions for expected output values

    // Test case 2: Invalid input
    data_in = 0;
    data_valid = 1;
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 2 failed: data_out_valid should be 1");
    // Add assertions for expected output values

    // Test case 3: Consecutive inputs
    data_in = {16'd10, 16'd20, 16'd30, 16'd40, 16'd50, 16'd60, 16'd70, 16'd80,
               16'd90, 16'd100, 16'd110, 16'd120, 16'd130, 16'd140, 16'd150, 16'd160,
               16'd170, 16'd180, 16'd190, 16'd200, 16'd210, 16'd220, 16'd230, 16'd240,
               16'd250, 16'd260, 16'd270, 16'd280, 16'd290, 16'd300, 16'd310, 16'd320};
    data_valid = 1;
    @(posedge clk);
    data_in = {16'd330, 16'd340, 16'd350, 16'd360, 16'd370, 16'd380, 16'd390, 16'd400,
               16'd410, 16'd420, 16'd430, 16'd440, 16'd450, 16'd460, 16'd470, 16'd480,
               16'd490, 16'd500, 16'd510, 16'd520, 16'd530, 16'd540, 16'd550, 16'd560,
               16'd570, 16'd580, 16'd590, 16'd600, 16'd610, 16'd620, 16'd630, 16'd640};
    @(posedge clk);
    data_valid = 0;
    #10;
    assert(data_out_valid == 1) else $error("Test case 3 failed: data_out_valid should be 1");
    // Add assertions for expected output values

    // Add more test cases as needed

    #100;
    $display("Testbench completed");
    $finish;
  end

  // Assertions
  always @(posedge clk) begin
    if (data_out_valid) begin
      assert(data_out >= 0) else $error("Output should be non-negative");
      // Add more assertions as needed
    end
  end

endmodule