`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/18 14:07:27
// Design Name: 
// Module Name: clk_make
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

module clk_make(
    input clk,
    input rst,
    
    output reg baud_clk
    );

    // endcount = clk freq/baud freq = 125MHz/500kHz = 250
    parameter endcnt = 10'd250;
    reg [9:0] clk_cnt = 0;

    always@(posedge clk) begin
        if(rst == 1) 
        begin
            clk_cnt <=10'd0;
            baud_clk <= 10'd0;
        end
        else if(clk_cnt == endcnt-1) 
        begin
            clk_cnt <= 10'd0; 
            baud_clk <= ~baud_clk;
        end
        else 
        begin
            clk_cnt <= clk_cnt + 10'd1;
            baud_clk <= baud_clk;
        end
    end

endmodule