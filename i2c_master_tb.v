`timescale 1ns/1ps
module i2c_master_tb; 

	reg clk; 
	reg reset; 
	reg [6:0] addr; 
	reg [7:0] data; 
	
	wire scl; 
	wire sda_out; 
	wire sda_oe; 
	wire [3:0] state; 
	
 i2c_master uut (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .data(data),
        .scl(scl),
        .sda_out(sda_out),
		  .sda_oe(sda_oe),
        .state(state)
    );
always #5 clk = ~clk; 

initial begin 
	clk = 0; 
	reset = 1; 
	addr = 7'b1010000; 
	data = 8'h3C; 
	
	#20 reset = 0; 
	#10000 $finish; 
end

initial begin
        $display("Time\tclk\tscl\tsda\tstate");
        $monitor("%g\t%b\t%b\t%b\t%d", $time, clk, scl, sda_out, state);
end

endmodule
