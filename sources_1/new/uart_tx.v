`timescale 1ns / 1ps
module uart_tx(clk, rx_data, uart_start,txd);
input clk;
input [63:0] rx_data;
input [1:0] uart_start;
output reg txd;

    reg [11:0] clk_cnt=0;//125MHZ를 115200보드레이트 맞추기 위해
    reg [3:0] tx_st=4'b0000;//idle,start,data,stop 상태 나타내기 위함
    reg [7:0] tx_result;//현재 보낼 문자가 무엇인지 나타내기 위함
    reg stst=0;//cnt 상태에 따라서.
    reg [3:0]txd_cnt=0;//byte 위치 나타냄
    reg tx_line_clear=1;
    reg [63:0] rx_data_buf;
    reg start_state;

    parameter IDLE_ST=0,
              START_ST=1,
              DATA_ST0=2,
              DATA_ST1=3,
              DATA_ST2=4,
              DATA_ST3=5,
              DATA_ST4=6,
              DATA_ST5=7,
              DATA_ST6=8,
              DATA_ST7=9,
              STOP_ST=10;

    always @* begin//언제든 
        if(tx_line_clear==1) begin
            rx_data_buf<=rx_data;
        end
        else
            rx_data_buf<=rx_data_buf;
    end
    
    /*always @* begin
        if(txd_cnt==0 && start_state !=1)
            tx_line_clear<=1;
        else
            tx_line_clear<=0;
    end*/
    
    always @* begin
        case(txd_cnt)
            4'b0000 : tx_result<=rx_data_buf[63:56]; //처음엔 
            4'b0001 : tx_result<=rx_data_buf[55:48];
            4'b0010 : tx_result<=rx_data_buf[47:40];
            4'b0011 : tx_result<=rx_data_buf[39:32];
            4'b0100 : tx_result<=rx_data_buf[31:24];
            4'b0101 : tx_result<=rx_data_buf[23:16];
            4'b0110 : tx_result<=rx_data_buf[15:8];
            4'b0111 : tx_result<=rx_data_buf[7:0];
            4'b1000 : tx_result<=8'h0D;//마지막엔 엔터 보내기
            default : tx_result<="";
        endcase
    end

    always @*   begin//clk나 뭐 어떤 것에도 상관 없이
        case(tx_st)
            IDLE_ST : txd<=1;
            START_ST : txd<=0;
            DATA_ST0 : txd<=tx_result[0];
            DATA_ST1 : txd<=tx_result[1];
            DATA_ST2 : txd<=tx_result[2];
            DATA_ST3 : txd<=tx_result[3];
            DATA_ST4 : txd<=tx_result[4];
            DATA_ST5 : txd<=tx_result[5];
            DATA_ST6 : txd<=tx_result[6];
            DATA_ST7 : txd<=tx_result[7];
            STOP_ST : txd<=1;
            default : txd<=1;
        endcase
    end

    always @(posedge clk) begin
        if(clk_cnt == 1084 || (uart_start==1 && tx_line_clear==1 && tx_st == IDLE_ST)) begin//1084 or 간격 좁을 경우 uart_start가 되는 순간 즉시 시작
            /*if(uart_start==1 && tx_line_clear==1)
                start_state<=1;*/
            tx_line_clear<=0;    
            clk_cnt<=0;
            case(tx_st)
                IDLE_ST : begin
                    if(uart_start == 1 || (txd_cnt > 0 && txd_cnt < 9) )begin
                        if(stst==0)//다 보내기 전엔
                            tx_st<=START_ST;
                        else//stst=1때 즉,,,다 보내면
                        begin
                            txd_cnt<=0;
                            tx_st<=START_ST;
                        end
                    end
                    else begin//txd_cnt==9
                        tx_st<=IDLE_ST;
                        txd_cnt<=0;
                        tx_line_clear<=1;
                end
                end
                START_ST : tx_st<=DATA_ST0;
                DATA_ST0 : tx_st<=DATA_ST1;
                DATA_ST1 : tx_st<=DATA_ST2;
                DATA_ST2 : tx_st<=DATA_ST3;
                DATA_ST3 : tx_st<=DATA_ST4;
                DATA_ST4 : tx_st<=DATA_ST5;
                DATA_ST5 : tx_st<=DATA_ST6;
                DATA_ST6 : tx_st<=DATA_ST7;
                DATA_ST7 : tx_st<=STOP_ST;
                STOP_ST : 
                begin
                    txd_cnt<=txd_cnt+1;
                    tx_st<=IDLE_ST;
                end
                default : tx_st<=IDLE_ST;
            endcase
        end
        else
            clk_cnt<=clk_cnt+1;
    end

    always @* begin//다 보내기 전까진 0
        if(txd_cnt<9) begin
            stst<=0;
        end
        else begin
            stst<=1;//다 보내고 나서 1,
        end
    end

endmodule