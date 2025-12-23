module i2c_master(
    input clk, reset,
    input [6:0] addr,
    input [7:0] data,
    output reg scl,
    output reg sda_out,
    output reg sda_oe,         // active high: master đang điều khiển SDA
    output reg [3:0] state
);

parameter STATE_IDLE    = 4'd0;
parameter STATE_START   = 4'd1;
parameter STATE_ADDR    = 4'd2;
parameter STATE_ACK1    = 4'd3;
parameter STATE_DATA    = 4'd4;
parameter STATE_ACK2    = 4'd5;
parameter STATE_PRESTOP = 4'd6;
parameter STATE_STOP    = 4'd7;

reg [7:0] addr_byte;
reg [7:0] data_byte;
reg [3:0] bit_cnt;
reg scl_clk;
reg scl_en;
reg [3:0] clk_div;

// SCL clock divider (f = clk / 10)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_div <= 0;
        scl_clk <= 1;
        scl_en <= 0;
    end else begin
        if (clk_div == 9) begin
            clk_div <= 0;
            scl_clk <= ~scl_clk;
            scl_en <= 1;
        end else begin
            clk_div <= clk_div + 1;
            scl_en <= 0;
        end
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        scl <= 1;
        sda_out <= 1;
        sda_oe <= 0;
        state <= STATE_IDLE;
        addr_byte <= 0;
        data_byte <= 0;
        bit_cnt <= 0;
    end else if (scl_en) begin
        scl <= scl_clk;

        case (state)
            STATE_IDLE: begin
                sda_out <= 1;
                sda_oe <= 1;
                scl <= 1;
                addr_byte <= {addr, 1'b0}; // R/W = 0
                data_byte <= data;
                bit_cnt <= 7;
                if (scl_clk == 0) begin
                    sda_out <= 0; // START condition
                    state <= STATE_START;
                end
            end

            STATE_START: begin
                if (scl_clk == 0) begin
                    sda_out <= addr_byte[bit_cnt];
                    state <= STATE_ADDR;
                end
            end

            STATE_ADDR: begin
                if (scl_clk == 0) begin
                    if (bit_cnt == 0) begin
                        state <= STATE_ACK1;
                        sda_oe <= 0; // release SDA, wait for ACK
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        sda_out <= addr_byte[bit_cnt - 1];
                    end
                end
            end

            STATE_ACK1: begin
                if (scl_clk == 0) begin
                    bit_cnt <= 7;
                    sda_oe <= 1; // reclaim SDA
                    sda_out <= data_byte[7];
                    state <= STATE_DATA;
                end
            end

            STATE_DATA: begin
                if (scl_clk == 0) begin
                    if (bit_cnt == 0) begin
                        state <= STATE_ACK2;
                        sda_oe <= 0; // release SDA, wait for ACK
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                        sda_out <= data_byte[bit_cnt - 1];
                    end
                end
            end

            STATE_ACK2: begin
                if (scl_clk == 0) begin
                    sda_oe <= 1;
                    sda_out <= 0;
                    state <= STATE_PRESTOP;
                end
            end

            STATE_PRESTOP: begin
                if (scl_clk == 0) begin
                    sda_out <= 0;
                end else begin
                    state <= STATE_STOP;
                end
            end

            STATE_STOP: begin
                if (scl_clk == 1) begin
                    sda_out <= 1;
                    sda_oe <= 1;
                    state <= STATE_IDLE;
                end
            end
        endcase
    end
end

endmodule
