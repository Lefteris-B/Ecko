`timescale 1ns / 1ps

module tb_i2c_slave;

    // Parameters
    parameter I2C_SLAVE_ADDRESS = 7'h45;

    // Inputs
    reg scl_i;
    reg sda_i;

    // Outputs
    wire sda_o;
    wire sda_t;
    wire [15:0] audio_data_o;
    wire audio_valid_o;

    // Instantiate the Unit Under Test (UUT)
    i2c_slave #(
        .I2C_SLAVE_ADDRESS(I2C_SLAVE_ADDRESS)
    ) uut (
        .scl_i(scl_i),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .audio_data_o(audio_data_o),
        .audio_valid_o(audio_valid_o)
    );

    // Testbench variables
    reg [7:0] i2c_addr;
    reg [15:0] i2c_data;
    reg [7:0] i2c_rw;
    integer i;

    // Clock generation
    initial begin
        scl_i = 0;
        forever #5 scl_i = ~scl_i;
    end

    // I2C start and stop conditions
    task i2c_start;
        begin
            sda_i = 1;
            #10;
            sda_i = 0;
            #10;
        end
    endtask

    task i2c_stop;
        begin
            sda_i = 0;
            #10;
            sda_i = 1;
            #10;
        end
    endtask

    // I2C write byte
    task i2c_write_byte;
        input [7:0] data;
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                sda_i = data[i];
                #10;
                scl_i = 1;
                #10;
                scl_i = 0;
                #10;
            end
            // Release SDA for ACK/NACK
            sda_i = 1;
            #10;
            scl_i = 1;
            #10;
            scl_i = 0;
            #10;
        end
    endtask

    // Test case: Verify I2C slave functionality
    initial begin
        // Initialize inputs
        sda_i = 1;
        i2c_addr = {I2C_SLAVE_ADDRESS, 1'b1};
        i2c_data = 16'h1234;

        // Generate I2C transaction
        #20;
        i2c_start();
        i2c_write_byte(i2c_addr);  // Write slave address with R/W bit set to 1 (read)
        i2c_write_byte(i2c_data[15:8]);  // Write data MSB
        i2c_write_byte(i2c_data[7:0]);   // Write data LSB
        i2c_stop();

        // Wait for audio data output
        wait(audio_valid_o);

        // Verify audio data
        assert(audio_data_o == i2c_data) else $fatal("ERROR: Expected audio data=%h, Actual audio data=%h", i2c_data, audio_data_o);

        // End simulation
        $display("All test cases passed!");
        $finish;
    end

endmodule
