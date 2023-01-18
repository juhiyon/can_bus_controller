`timescale 1ns / 1ps

module tx_block(
    input clk,
	input baud_clk,
	input rst,

	input[10:0] address_tx,
	input [63:0] tx_data,
	input tx_start,
			
	output reg can_tx,
	output txing
    );

    //repeat tx flag
	parameter  init = 2'h0,  ones = 2'h1, zeros = 2'h2;
	
	//to know the bit_stuff
	reg[1:0] c_state=0, n_state=0;
	reg[31:0] bit_stuffing_count = 0;
	reg bit_stuffing = 0;
	wire can_bitstuff;//Flag the bitstuff area
	reg ch_st=0;//ch_st = 1:bitstuff occurrence, 0 : Does not occur
	reg tx_buf_reg;
	
	transmitter transmitter(clk,baud_clk,rst,address_tx,tx_data,tx_start,ch_st,tx_buf,can_bitstuff,txing);

    always @ (posedge baud_clk or posedge rst) begin
        if(rst) begin
            bit_stuffing_count<= 0;
            bit_stuffing <= 0;
        end
        else begin
            if(n_state != c_state) begin//Do it only when the tx_value is equal.
                bit_stuffing_count<= 0;
                bit_stuffing <= 0;
            end
            else if(!can_bitstuff) begin//Only in the bitstuff area.
                bit_stuffing_count <= 0;
                bit_stuffing <= 0;
            end 
            else if(bit_stuffing_count >= 4)begin//To make the interval to send opposite value
                bit_stuffing_count <= 0;
                bit_stuffing <= 0;
            end
            else if(bit_stuffing_count >= 3)begin//Flag that received five equal values
                bit_stuffing_count <= bit_stuffing_count + 1;
                bit_stuffing <= 1;//Flag the stuff bit
            end
            else begin
                bit_stuffing_count <= bit_stuffing_count +1;
                bit_stuffing <= 0;
            end
        end
    end

    always @ (posedge baud_clk) begin
        c_state <= n_state;
    end

    always @ (tx_buf) begin//To know the current tx value
        if(tx_buf == 1) begin
            n_state<= ones;
        end
        else begin
            n_state <= zeros;
        end
    end

    always @ (bit_stuffing or tx_buf) begin
        if(bit_stuffing) begin
            can_tx <= ~tx_buf_reg;//Send the stuff bit(Opposite of previous value)
            ch_st<=1;//After sending the stuff bit, restart the process you were originally doing
        end
        else begin
            can_tx <= tx_buf;
            ch_st<=0;
            tx_buf_reg <= tx_buf;//To send the oppsite value when ocurr the bitstuff
        end
    end
	
endmodule