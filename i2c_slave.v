module i2c_slave (
	input wire clk, 
	input wire reset, 
	input wire scl, 
	inout wire sda, 
	output reg [7:0] received_data,
	output reg data_valid,
	output reg [2:0] state
);

	parameter SLAVE_ADDR = 7'b1010000;
	
	localparam STATE_IDLE = 0,
				  STATE_ADDR = 1,
				  STATE_ACK1 = 2, 
				  STATE_DATA = 3,
				  STATE_ACK2 = 4; 
				  
	reg [3:0] bit_cnt;
	reg [7:0] shift_reg; 
	
	reg sda_out; 
	reg sda_oe; 
	assign sda = sda_oe ? sda_out : 1'bz;
	wire sda_in = sda; 
	
	reg scl_prev; 
	wire scl_posedge = (scl == 1) && (scl_prev == 0); 
	wire scl_negedge = (scl == 0) && (scl_prev == 1); 
	
	always @(posedge clk or posedge reset) begin 
		if(reset) begin 
			state <= STATE_IDLE; 
			bit_cnt <= 0; 
			shift_reg <= 0; 
			sda_out <= 1; 
			received_data <= 0; 
			data_valid <= 0; 
			scl_prev <= scl; 
		end else begin 
			scl_prev <= scl; 
			data_valid <= 0; 
			
			case(state) 
				STATE_IDLE: begin 
					sda_oe <= 0; 
					if(scl == 1 && sda_in == 0) begin 
						state <= STATE_ADDR; 
						bit_cnt <= 7; 
					end
				end
				
				STATE_ADDR: begin 
					if(scl_posedge) begin 
						shift_reg[bit_cnt] <= sda_in; 
						if(bit_cnt == 0) 
							state <= STATE_ACK1;
						else
							bit_cnt <= bit_cnt - 1; 
					end
				end
		
				STATE_ACK1: begin 
					if(scl_negedge) begin 
						if(shift_reg[7:1] == SLAVE_ADDR && shift_reg[0] == 0) begin 
							sda_out <= 0; //ack 
						end else begin 
							sda_out <= 1; //nack
						end
						sda_oe <= 1; 
					end else if (scl_posedge) begin 
						sda_oe <= 0; 
						if(sda_out == 0) begin 
							bit_cnt <= 7; 
							state <= STATE_DATA;
						end else begin 
							state <= STATE_IDLE; 
						end
					end
				end
				
					STATE_DATA: begin 
						if(scl_posedge) begin 
							shift_reg[bit_cnt] <= sda_in; 
							if(bit_cnt == 0) 
								state <= STATE_ACK2;
							else
								bit_cnt <= bit_cnt - 1; 
						end
					end
					
					STATE_ACK2: begin 
						if(scl_negedge) begin 	
							sda_out <= 0; 
							sda_oe <= 1; 
						end else if (scl_posedge) begin 
							sda_oe <= 0; 
							received_data <= shift_reg; 
							data_valid <= 1; 
							state <= STATE_IDLE; 
						end
					end
				endcase
			end
		end
endmodule 
	