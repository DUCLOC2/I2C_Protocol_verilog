`timescale 1ns / 1ps

module i2c_top_tb;

    reg clk;
    reg reset;
    reg [6:0] addr;
    reg [7:0] data_in;
    wire scl;
    wire sda;
    wire [3:0] state;
    wire [7:0] received_data;
    wire data_valid;

    // Instantiate the top module
    i2_top uut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .data_in(data_in),
        .scl(scl),
        .sda(sda),
        .state(state),
        .received_data(received_data),
        .data_valid(data_valid)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Test stimulus
   initial begin
    reset = 1;
    clk = 0;
    #20 reset = 0;

    // Truyền 1
    addr = 7'b1010001;
    data_in = 8'b1010101;  // 0xA5
    #2000;

    // Truyền 2
    addr = 7'b1010010;
    data_in = 8'b1100110;  // 0xC6
    #2000;

    // Truyền 3
    addr = 7'b1010000;
    data_in = 8'b1111000;  // 0xF8
    #2000;

    // Truyền 4
    addr = 7'b1010111;
    data_in = 8'b0001111;  // 0x0F
    #2000;

    $stop;
end


endmodule
