`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/18 14:35:52
// Design Name: 
// Module Name: transmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module transmitter(
    input clk,
	input baud_clk,
	input rst,
    
    input[10:0] address_tx,
    input [63:0] tx_data,
    input tx_start,
    
	input ch_st,//¹Ù²ñ ¾È¹Ù²ñ »óÅÂ
	
	output reg tx,
	output reg can_bitstuff,//ÇöÀç ÀÌ state°¡ bitstuff areaÀÎÁö flag
	output reg txing
	);

//ch_st=1 : Immediately after sending the opposite beat due to bitstuffing, the time it returned to its original state.
	parameter all_ones = 15'b111111111111111;
	parameter idle = 8'h0,  start_of_frame = 8'h1, addressing =8'h2 ,rtr = 8'h3 ,ide = 8'h4, reserve_bit = 8'h5, num_of_bytes = 8'h6,
			data_out = 8'h7, crc_out = 8'h8, crc_delimiter = 8'h9 , ack = 8'hA, ack_delimiter =  8'hB, end_of_frame = 8'hC, ifs=8'hD;

	parameter bytes = 5'd8;
	reg[10:0] address_count = 0, crc_count = 0, eof_count = 0 , data_bit_count = 0, data_byte_count = 0, ifs_count=0;
	reg[7:0] c_state=0, n_state=0;
	initial txing = 0;
	
	reg[14:0] crc_output, crc_holder;
	wire crc_en;
	wire[14:0] crc_buff;
	reg crc_initial=0;
	
	crc crc(clk,rst,tx_data,crc_en, crc_initial,crc_buff);
	oneshot oneshot(clk, rst, tx_start, crc_en);

	always @(crc_buff or crc_holder) begin
		if(crc_buff != all_ones) //crc_buff °ªÀÌ 15'b1 ¾Æ´Ò¶© crc_output¿¡ crc_buff
			crc_output <= crc_buff;
		else//crc_buff °ªÀÌ 15'b1 ÀÏ ¶© crc_output¿¡ crc_buff
			crc_output <= crc_holder;
	end
	
	always @ (posedge clk or posedge rst) begin
		if(rst == 1) begin
			crc_holder <= 15'd0;
		end
		else begin
			crc_holder <= crc_output;
		end
	end
	
	//Update Logic
    always @ (posedge baud_clk or posedge rst) begin
        if(rst == 1) begin
            c_state <= 32'd0;
        end
        else begin
        if(ch_st==1)//After beatstuffing, the current step is the same.
            c_state<=c_state;
        else
            c_state <= n_state; 
        end
    end

	//Counting Logic
	always @ (posedge baud_clk) begin
        if(ch_st==1) begin
           address_count <= address_count;
           data_bit_count<= data_bit_count;
           data_byte_count<= data_byte_count;
           crc_count <= crc_count; 
           eof_count <= eof_count;
           ifs_count<=ifs_count;
        end
        else begin
            case(c_state) 
                idle: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                start_of_frame:begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                addressing: begin
                    address_count <= address_count + 1'b1;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                rtr: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                end
                ide: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                reserve_bit: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                num_of_bytes: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= data_byte_count +1'b1;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                data_out: begin
                    address_count <= 11'd0;
                    data_bit_count<= data_bit_count +1'b1;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                crc_out: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= crc_count + 1'b1; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                crc_delimiter: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                ack: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                ack_delimiter:begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=11'd0;
                end
                end_of_frame: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= eof_count +1'b1;
                    ifs_count<=11'd0;
                end
                ifs: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count<=ifs_count +1'b1;
                end
                default: begin
                    address_count <= 11'd0;
                    data_bit_count<= 11'd0;
                    data_byte_count<= 11'd0;
                    crc_count <= 11'd0; 
                    eof_count <= 11'd0;
                    ifs_count <= 11'd0; 
                end
            endcase
        end
    end

	//Next State Logic
	always @ (c_state or tx_data or tx_start or address_count or data_byte_count
		or data_bit_count or crc_count or eof_count or crc_output or clk or ifs_count) begin
		if(ch_st == 1) begin//The next step of bitstuffing remains the same.
		   n_state<=n_state;
		end
		else begin//Or,move on.
            case(c_state)
                idle: begin
                    if(tx_start) begin
                        n_state <= start_of_frame;
                    end
                    else begin
                        n_state <= idle;
                    end
                end
                start_of_frame: begin
                    n_state <= addressing;
                end
                addressing: begin
                //I will make fpga act as the main pc.
                //(I will signal the sensor and read the sensor value.)
                //Therefore, the tx ID data does not need to be compared with the rx ID.
                    if(address_count == 11'd10) begin
                        n_state <= rtr;
                    end
                    else begin
                        n_state <= addressing;
                    end
                end
                rtr: begin
                    n_state <= ide;
                end
                ide: begin
                    n_state <= reserve_bit;
                end
                reserve_bit: begin
                    n_state <= num_of_bytes;
                end
                num_of_bytes: begin
                    if(data_byte_count == 11'd3) begin
                        n_state <= data_out;
                    end
                    else begin
                        n_state <= num_of_bytes;
                    end
                end
                data_out: begin
                    if(data_bit_count == 11'd63) begin
                        n_state <= crc_out;
                    end
                    else begin
                        n_state <= data_out;
                    end
                end
                crc_out: begin
                    if(crc_count == 11'd14) begin
                        n_state <= crc_delimiter;
                    end
                    else begin
                        n_state <= crc_out;
                    end
                end
                crc_delimiter: begin
                    n_state <= ack;
                end
                ack: begin
                    n_state <= ack_delimiter;
                end
                ack_delimiter: begin
                    n_state <= end_of_frame;
                end
                end_of_frame: begin
                    if(eof_count == 11'd6) begin
                        n_state <= ifs;
                    end
                    else begin
                        n_state <= end_of_frame;
                    end
                end
                ifs: begin
                    if(ifs_count == 11'd3) begin
                        n_state <= idle;
                    end
                    else begin
                        n_state <= ifs;
                    end
                end
                default:
                begin
                    n_state <= idle;
                end
            endcase
		end
	end

	//Output Logic
	always @(c_state or address_tx or tx_data or crc_output or crc_count or data_byte_count or data_bit_count or address_count) begin
        if(ch_st==1) begin
           tx<=tx;
        end
        else begin
            case(c_state) 
                idle: begin
                    tx <= 1;
                    can_bitstuff <= 0;
                    txing <= 1'b0;
                end
                addressing: begin
                    tx <= address_tx[11'd10-address_count];
                    can_bitstuff <= 1;
                    txing <= 1'b1;
                end
                start_of_frame: begin
                    tx<= 0;
                    can_bitstuff <= 1'b1;
                    txing <= 1'b1;
                end
                rtr: begin
                    tx <= 0;
                    can_bitstuff <= 1;
                    txing <= 1'b1;
                end
                ide: begin
                    tx <= 0;
                    can_bitstuff <= 1;
                    txing <= 1'b1;
                end
                reserve_bit: begin
                    tx <= 0;
                    can_bitstuff <= 1;
                    txing <= 1'b1;
                end
                num_of_bytes: begin
                    tx <= bytes[11'd3-data_byte_count];
                    can_bitstuff <= 1;
                    txing <= 1'b1;
                end
                data_out: begin
                    tx <= tx_data[11'd63-data_bit_count];
                    can_bitstuff <= 1;
                    txing <= 1'b1;
                end
                crc_out: begin
                    tx <= crc_output[11'd14-crc_count];
                    can_bitstuff <= 1;
                    txing <= 1'b1;
                end
                crc_delimiter: begin
                    tx <= 1;
                    can_bitstuff <= 0;
                    txing <= 1'b1;
                end
                ack: begin
                    tx <= 1;
                    can_bitstuff <= 0;
                    txing <= 1'b1;
                end
                ack_delimiter:begin
                    tx <= 1;
                    can_bitstuff <= 0;
                    txing <= 1'b1;
                end
                end_of_frame: begin
                    tx <= 1;
                    can_bitstuff <= 0;
                    txing <= 1'b1;
                end
                end_of_frame: begin
                    tx <= 1;
                    can_bitstuff <= 0;
                    txing <= 1'b1;
                end
                default: begin
                    tx <= 1;
                    can_bitstuff <= 0;
                    txing <= 1'b1;
                end
            endcase
		end
	end

endmodule