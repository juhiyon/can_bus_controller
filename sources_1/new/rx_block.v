`timescale 1ns / 1ps

module rx_block(
    input clk,
	input baud_clk,
	input rst,
	
	input[10:0] address_rx,//아이디 맞으면 수신, 아니면 오류
	input can_rx,
	input rx_start,
	
	output reg rxing,
	output reg [63:0] rx_data,//데이터랑 rxing만 보내고
	output reg [1:0] uart_start	
    );
    
    parameter all_ones = 15'b111111111111111;
	parameter idle = 8'h0,  start_of_frame = 8'h1, addressing =8'h2 ,rtr = 8'h3 ,ide = 8'h4, reserve_bit = 8'h5, num_of_bytes = 8'h6,
			data_in = 8'h7, crc_out = 8'h8, crc_delimiter = 8'h9 , ack = 8'hA, ack_delimiter =  8'hB, end_of_frame = 8'hC, ifs = 8'hD;

    parameter bytes = 5'd8;
	reg[10:0] address_count = 0, crc_count = 0, eof_count = 0 , data_bit_count = 0, data_byte_count = 0, ifs_count=0;
	reg[7:0] c_state=0, n_state=0;
	
	reg can_bitstuff=0;
	reg add_err=0;
	reg crc_err=0;
	reg usual_err=0;
	reg [3:0] data_byte_width=4'd0;
	reg crc_en=0;
	wire [14:0] crc_output;
	reg crc_ch=0;
	reg crc_initial=0;
	
	initial rxing = 0;
	initial rx_data=64'd0;
	
	crc crc(clk, rst, rx_data,crc_en,crc_initial,crc_output);
	
	always @(negedge clk) begin
        if(data_bit_count == 11'd63 && crc_ch==0) begin
            crc_en<=1;
            crc_ch<=1;
        end
        else if(data_bit_count == 11'd63 && crc_ch==1)
            crc_en<=0;
        else begin
            crc_ch<=0;
        end
        if(c_state == 8'h0)
            crc_initial<=1;
        else
            crc_initial<=0;
    end
	
	//Update Logic
	always @ (posedge baud_clk or posedge rst) begin
		if(rst == 1) begin
			c_state <= 32'd0;
		end
		else begin
            if(ch_st == 1)
                c_state<=c_state;
		else
			c_state <= n_state;
		end
	end
	
	reg ch_st=0;
	reg rx=0;
	reg [5:0]bit_stuffing_count=6'd0;
	
	always @ (posedge baud_clk) begin
	   rx<=can_rx;
	   ch_st<=0;
	   if(can_bitstuff==1 && can_rx==rx) begin
	       bit_stuffing_count<=bit_stuffing_count+1;
	       if(bit_stuffing_count == 3) begin
	           ch_st<=1;
	           bit_stuffing_count<=0;
	       end
	   end
	   else begin
	       bit_stuffing_count<=0;
	   end
	end
	
	//Counting Logic
	always @ (posedge baud_clk) begin//음,,같은 값 다섯번 들어오면
	if(ch_st==1)
	begin
	   address_count <= address_count;
       data_bit_count<= data_bit_count;
       data_byte_count<= data_byte_count;
       crc_count <= crc_count; 
       eof_count <= eof_count;
	   ifs_count <= ifs_count; 
	end
	else
	begin
		case(c_state) 
			idle: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			start_of_frame:begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
			end
			addressing: begin
			    address_count <= address_count + 1'b1;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			rtr: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			ide: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			reserve_bit: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			num_of_bytes: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= data_byte_count +1'b1;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			data_in: begin
				address_count <= 11'd0;
				data_bit_count<= data_bit_count +1'b1;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			crc_out: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= crc_count + 1'b1; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			crc_delimiter: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			ack: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			ack_delimiter:begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= 11'd0; 
			end
			end_of_frame: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= eof_count +1'b1;
				ifs_count <= 11'd0; 
			end
			ifs: begin
				address_count <= 11'd0;
				data_bit_count<= 11'd0;
				data_byte_count<= 11'd0;
				crc_count <= 11'd0; 
				eof_count <= 11'd0;
				ifs_count <= ifs_count +1'b1;
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
	always @ (c_state or can_rx or rx_start or address_count or data_byte_count or data_bit_count or crc_count or eof_count or crc_output or crc_err or ifs_count) 
		begin
		if(ch_st == 1)
		begin
		   n_state<=n_state;
		end
		else
		begin
		case(c_state)
			idle: begin
				if(rx_start==1) begin
					n_state <= start_of_frame;
				end
				else begin
					n_state <= idle;
				end
			end
			start_of_frame: begin
			    if(can_rx == 0)
			 	   n_state <= addressing;
			end
			addressing: begin
				if(address_count >= 11'd10) begin
					n_state <= rtr;
				end
				else begin
					n_state <= addressing;
				end
			end
			rtr: begin
				if(can_rx==0) begin
			     	n_state <= ide;
			    end
			    else begin
			        n_state <= idle;
			    end
		    end
			ide: begin
			    if(can_rx==0) begin
			     	n_state <= reserve_bit;
			    end
			    else begin
			        n_state <= idle;
			    end
		    end
			reserve_bit: begin
				if(can_rx==0) begin
			     	n_state <= num_of_bytes;
			    end
			    else begin
			        n_state <= idle;
			    end
		    end
			num_of_bytes: begin
				if(data_byte_count == 11'd3) begin
					n_state <= data_in;
				end
				else begin
					n_state <= num_of_bytes;
				end
			end
			data_in: begin
				if(data_bit_count == 11'd63) begin
					n_state <= crc_out;
				end
				else begin
					n_state <= data_in;
				end
			end
			crc_out: begin
			    if(crc_err == 1) begin
			        n_state <= idle;
			    end 
			    else begin
                    if(crc_count == 11'd14) begin
                        n_state <= crc_delimiter;
                    end
                    else begin
                        n_state <= crc_out;
                    end
                end
			end
			crc_delimiter: begin
				if(can_rx==1) begin
			     	n_state <= ack;
			    end
			    else begin
			        n_state <= idle;
			    end
		    end
			ack: begin
				if(can_rx==1) begin
			     	n_state <= ack_delimiter;
			    end
			    else begin
			        n_state <= idle;
			    end
		    end
			ack_delimiter: begin
				if(can_rx==1) begin
			     	n_state <= end_of_frame;
			    end
			    else begin
			        n_state <= idle;
			    end
		    end
			end_of_frame: begin
				if(eof_count == 11'd6) begin
					n_state <= ifs;//ifs frame 넣어줘야 하는듯
				end
				else begin
					n_state <= end_of_frame;
				end
			end
			ifs: begin
				if(ifs_count == 11'd3) begin
					n_state <= idle;//ifs frame 넣어줘야 하는듯
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
	
	//input Logic
	always @(c_state or address_rx or crc_count or data_byte_count or data_bit_count or address_count or can_rx) 
	begin
		case(c_state) 
			idle: begin
				can_bitstuff <= 0;
				rxing <= 1'b0;
				crc_err<=0;  
				uart_start<=2'b00;
			end
			addressing: begin
				can_bitstuff <= 1;
				rxing <= 1'b1;
				uart_start<=2'b00;
				crc_err<=0;  
				if(can_rx != address_rx[11'd10-address_count]) begin
				    add_err<=1;
				end
				else
				    add_err<=0;
			end
			start_of_frame: begin
				can_bitstuff <= 1;
				rxing <= 1'b1;
				crc_err<=0;  
				uart_start<=2'b00;
			end
			rtr: begin
				can_bitstuff <= 1;
				rxing <= 1'b1;
				crc_err<=0;  
				uart_start<=2'b00;
			end
			ide: begin
				can_bitstuff <= 1;
				rxing <= 1'b1;
				crc_err<=0;  
				uart_start<=2'b00;
			end
			reserve_bit: begin
				can_bitstuff <= 1;
				rxing <= 1'b1;
				crc_err<=0;  
				uart_start<=2'b00;
			end
			num_of_bytes: begin
			    can_bitstuff <= 1;
				rxing <= 1'b1;
				data_byte_width[11'd3-data_byte_count]<=can_rx;
				crc_err<=0;  
				uart_start<=2'b00;;
			end
			data_in: begin
			    rx_data[11'd63-data_bit_count]<=can_rx;
				can_bitstuff <= 1;
				rxing <= 1'b1;
				crc_err<=0;  
				uart_start<=2'b00;
			end
			crc_out: begin
                if(crc_output[11'd14-crc_count] != can_rx) begin
                     crc_err<=1;
                end
                else begin
                     crc_err<=0;
                end
                can_bitstuff <= 1;
                rxing <= 1'b1;
                uart_start<=2'b00;
			end
			crc_delimiter: begin
				uart_start<=2'b01;
			    crc_err<=0;   
				can_bitstuff <= 0;
				rxing <= 1'b1;
			end
			ack: begin
				uart_start<=2'b00;
				can_bitstuff <= 0;
				rxing <= 1'b1;
				crc_err<=0;  
			end
			ack_delimiter:begin
				uart_start<=2'b00;
				can_bitstuff <= 0;
				rxing <= 1'b1;
				crc_err<=0;  
			end
			end_of_frame: begin
				uart_start<=2'b00;
				can_bitstuff <= 0;
				rxing <= 1'b1;
				crc_err<=0;  
			end
			ifs: begin
				uart_start<=2'b00;
				can_bitstuff <= 0;
				rxing <= 1'b1;
				crc_err<=0;  
			end
			default: begin
				uart_start<=2'b00;
				can_bitstuff <= 0;
				rxing <= 1'b1;
				crc_err<=0;  
			end
		endcase
    end
	
endmodule