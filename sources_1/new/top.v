`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/18 14:05:10
// Design Name: 
// Module Name: top
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

module top(
    //can data of tx and rx
	output can_tx,
	input can_rx,
	
	input clk,
	input rst,
	
	input tx_start,//Button to start can tx
	input rx_start,//Button to start can rx
	
	input [7:0] transmit_data,//Data to send
	
	//uart
	output txd
	);
		
	//Sending or receiving data
	wire txing;
	wire rxing;
	
	wire [63:0] tx_data;
	wire [63:0] rx_data;
	
	//Flag to start uart tx
	wire [1:0] uart_start;
	
	wire baud_clk;
	
	//Device address tx and rx
	parameter address_tx = 11'h10;
	parameter address_rx = 11'h10;
	
	assign tx_data = {8{transmit_data}};
	
	//To generate the can baud_clk
	clk_make clk_make(clk,rst,baud_clk);

	//Can tx block
	tx_block tx_block(clk,baud_clk,rst,address_tx,tx_data,tx_start,can_tx,txing);
	
	//Can rx block
    rx_block rx_block(clk,baud_clk,rst,address_rx,can_rx,rx_start,rxing,rx_data,uart_start);
    
    //Uart tx block
    uart_tx uart_tx(clk, rx_data, uart_start,txd);
	
endmodule