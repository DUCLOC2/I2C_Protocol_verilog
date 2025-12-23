`timescale 1ns / 1ps

module i2c_slave_tb;

    reg clk;
    reg reset;
    reg scl;
    wire sda;
    
    wire [7:0] received_data;
    wire data_valid;
    wire [2:0] state;

    reg sda_drive;
    reg sda_out;
    assign sda = sda_drive ? sda_out : 1'bz;

    i2c_slave uut (
        .clk(clk),
        .reset(reset),
        .scl(scl),
        .sda(sda),
        .received_data(received_data),
        .data_valid(data_valid),
        .state(state)
    );

    // Clock 100MHz
    always #5 clk = ~clk;

    task send_bit(input reg b);
        begin
            sda_drive = 1;
            sda_out = b;
            #100; scl = 1; #100; scl = 0;
        end
    endtask

    task release_sda;
        begin
            sda_drive = 0;
            #100; scl = 1; #100; scl = 0;
        end
    endtask

    task send_start;
        begin
            sda_drive = 1;
            sda_out = 1; scl = 1; #100;
            sda_out = 0; #100; scl = 0; // START condition
        end
    endtask

    task send_stop;
        begin
            sda_out = 0; scl = 1; #100;
            sda_out = 1; #100;
        end
    endtask

    task send_byte(input [7:0] byte);
        integer i;
        begin
            for(i = 7; i >= 0; i = i - 1)
                send_bit(byte[i]);
        end
    endtask

    initial begin
        // Init
        clk = 0;
        reset = 1;
        scl = 1;
        sda_drive = 0;
        sda_out = 1;

        // Reset
        #50;
        reset = 0;

        // Send START + Address + Data + STOP
        #200;

        send_start();                     // START
        send_byte(8'b10100000);           // Address: 0x50 + Write (0)
        release_sda();                    // Wait for ACK from slave
        #200;
        send_byte(8'h3C);                 // Send data byte
        release_sda();                    // Wait for ACK from slave
        #200;
        send_stop();                      // STOP

        #1000;
        $display("Received: %h", received_data);
        $finish;
    end
    initial begin
        $monitor("Time=%t scl=%b sda=%b state=%d received_data=%h valid=%b", 
                  $time, scl, sda, state, received_data, data_valid);
    end

endmodule
