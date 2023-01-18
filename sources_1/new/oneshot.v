`timescale 1ns / 1ps

module oneshot(
    input clk,
    input rst,
    
    input tx_start,
    
    output reg crc_en
    );
    
    initial crc_en = 0;
    parameter waiting_l = 2'b00, on = 2'b01, waiting_h = 2'b10;
    reg[1:0] next_state, current_state;
    
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            current_state <= waiting_l;
        end
        else begin
            current_state <= next_state;
        end
    end

    always @ (current_state or tx_start) begin
        if(current_state == on) begin
            next_state <= waiting_h;
        end
        else if(current_state == waiting_h) begin
            if(tx_start) begin
                next_state <= waiting_h;
            end
            else begin
                next_state <= waiting_l;
            end
        end
        else if(tx_start) begin
            next_state<= on;
        end
        else begin
            next_state<= waiting_l;
        end
    end

    always @(current_state or rst) begin
        if(rst)
            crc_en <= 1'b0;
        else if(current_state == on)
            crc_en <= 1'b1;
        else 
            crc_en <= 1'b0;
    end

endmodule