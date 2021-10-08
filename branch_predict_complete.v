`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/08 10:39:47
// Design Name: 
// Module Name: branch_predict_complete
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


module branch_predict_complete(
    input wire clk, rst,

    input wire pred_globalD, pred_localD,
    input wire pred_globalM, pred_localM,

    input wire [13:0] CPHT_indexD, CPHT_indexM,

    input wire actual_takeM,

    output wire pred_takeD 
    );
    // 初始化数据
    parameter Saturated_PG = 2'b00, UnSaturated_PG = 2'b01, Saturated_PL = 2'b11, UnSaturated_PL = 2'b10;
    parameter CPHT_DEPTH = 14;

    //初始化CPHT
    reg [1:0] CPHT [(1<<CPHT_DEPTH)-1:0];

    integer i;

    // 根据 CPHT[CPHT_indexD] 的值预测 pred_takeD
    assign pred_takeD = CPHT[CPHT_indexD][1]==1?pred_localD:pred_globalD;

    //CPHT更新
    wire [1:0] statue;
    assign statue = {(actual_takeM==pred_globalM)?1:0,(actual_takeM==pred_localM)?1:0};
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<CPHT_DEPTH); i=i+1) begin
                CPHT[i] <= Saturated_PL;
            end
        end
        else begin
            case(CPHT[CPHT_indexM])
                // 
                Saturated_PL:begin
                    if(statue==10) begin
                        CPHT[CPHT_indexM] <= UnSaturated_PL;
                    end
                    else begin
                        CPHT[CPHT_indexM] <= Saturated_PL;
                    end
                end
                UnSaturated_PL:begin
                    if(statue==10) begin
                        CPHT[CPHT_indexM] <= UnSaturated_PG;
                    end
                    else if(statue==01) begin
                        CPHT[CPHT_indexM] <= Saturated_PL;
                    end
                    else begin
                        CPHT[CPHT_indexM] <= UnSaturated_PL;
                    end
                end
                UnSaturated_PG:begin
                    if(statue==10) begin
                        CPHT[CPHT_indexM] <= Saturated_PG;
                    end
                    else if(statue==01) begin
                        CPHT[CPHT_indexM] <= UnSaturated_PL;
                    end
                    else begin
                        CPHT[CPHT_indexM] <= UnSaturated_PG;
                    end
                end
                Saturated_PG:begin
                    if(statue==01) begin
                        CPHT[CPHT_indexM] <= UnSaturated_PG;
                    end
                    else begin
                        CPHT[CPHT_indexM] <= Saturated_PG;
                    end
                end
            endcase 
        end
    end
endmodule
