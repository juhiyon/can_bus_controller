`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/18 15:17:45
// Design Name: 
// Module Name: top_tb
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

module top_tb;

	// Inputs
	assign can_rx = can_tx;
	
	reg rst;
	reg clk;
	
	reg tx_start;
	reg rx_start;
	
	reg [7:0] transmit_data;
	
	// Outputs
	wire can_tx;

	top top (
		.can_tx(can_tx), 
		.can_rx(can_rx), 
		.rst(rst),
		.clk(clk),
		.tx_start(tx_start), 
		.rx_start(rx_start),
		.transmit_data(transmit_data),
		.txd(txd)
	);

    parameter step=10;
    always #(step/2) clk=~clk;
	 
	initial begin
		// Initialize Inputs
		clk=0;
		rst = 1;
		tx_start = 0;
		rx_start = 0;
		//transmit_data = 8'b00110001;
        transmit_data = 8'b11101000;
        
		// Wait 100 ns for global reset to finish
		// Wait 100 ns for global reset to finish
		#100;
		#100 rst = 0;
		#1000 tx_start = 1; rx_start=0;
		#800100;
		#100;
		rx_start=1;
	end
     
endmodule
