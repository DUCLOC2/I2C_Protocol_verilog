module i2_top (
    input wire clk,
    input wire reset,
    input wire [6:0] addr,
    input wire [7:0] data_in,
    output wire scl,
    inout wire sda,
    output wire [3:0] state,           // trạng thái của master
    output wire [7:0] received_data,
    output wire data_valid
);

    wire sda_out_master, sda_oe_master;
    wire sda_slave_io;

    // SDA control: Master drives SDA when sda_oe_master is 1, otherwise high-impedance
    assign sda = sda_oe_master ? sda_out_master : 1'bz;

    i2c_master master_inst (
        .clk(clk),
        .reset(reset),
        .addr(addr),
        .data(data_in),
        .scl(scl),
        .sda_out(sda_out_master),
        .sda_oe(sda_oe_master),
        .state(state)
    );

    i2c_slave slave_inst (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .received_data(received_data),
        .data_valid(data_valid),
        .state()
    );

endmodule
