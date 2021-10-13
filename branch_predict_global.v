`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/07 19:10:40
// Design Name: 
// Module Name: branch_predict_global
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


module branch_predict_global(
    input wire clk, rst,

    input wire flushD,flushE,flushM,
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,

    input wire [31:0] instrF,

    input wire branchM,         
    input wire actual_takeM, pred_takeM,  


    input wire branchD,        
    output wire pred_takeD,
    output wire [9:0] PHT_index, update_PHT_index  
    );
    wire pred_takeF;
    wire branchF;
    reg pred_takeF_r;
    wire [3:0] GHTD, GHTE, GHTM;

// 初始化数据
    // 常数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 10;
    parameter GHT_DEPTH = 1;

    // GHT PHT GHT_realM寄存器
    reg [9:0] GHT, GHT_realM;
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];

    integer i, j;

// -------------------------------------根据pcF和GHT预测pred_takeF------------------------------------------

    assign PHT_index = pcF[11:2]^GHT;
    assign branchF = (instrF[31:26]==6'b000100 | instrF[31:26]==6'b000101 | instrF[31:26]==6'b000001 | instrF[31:26]==6'b000111 | instrF[31:26]==6'b000110)?1:0;
    assign pred_takeF = PHT[PHT_index][1];

        // --------------------------pipeline------------------------------
            always @(posedge clk) begin
                if(rst | flushD) begin
                    pred_takeF_r <= 0;
                end
                else if(~stallD) begin
                    pred_takeF_r <= pred_takeF;
                end
            end

            floprc #(4) GHT_D( .clk(clka), .rst(rst), .en(~stallD), .clear(flushD), .d(GHT), .q(GHTD) );

            floprc #(4) GHT_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE), .d(GHTD), .q(GHTE) );

            floprc #(4) GHT_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM), .d(GHTE), .q(GHTM) );
        // --------------------------pipeline------------------------------

// ---------------------------------初始化和更新GHT GHT_realM----------------------------------
    always@(posedge clk) begin
        if(rst) begin
            GHT <= 0;
        end
        else if(branchF&~flushD) begin
            // F阶段是branch指令并且又没预测错误更新GHT
            if(pred_takeF) begin
                GHT <= (GHT<<1)+1;
            end
            else begin
                GHT <= (GHT<<1);
            end
        end
        else if(branchM&~(actual_takeM==pred_takeM)) begin
            // 预测错误时修改GHT
            if(pred_takeF) begin
                GHT <= (GHT_realM<<1)+1;
            end
            else begin
                GHT <= (GHT_realM<<1);
            end
        end
    end

    always@(posedge clk) begin
        if(rst) begin
            GHT_realM <= 0;
        end
        else if(branchM) begin
            // 
            if(actual_takeM) begin
                GHT_realM <= (GHT_realM<<1)+1;
            end
            else begin
                GHT_realM <= (GHT_realM<<1);
            end
        end
    end
// ---------------------------------初始化和更新GHT GHT_realM----------------------------------


// ---------------------------------初始化和更新PHT----------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    assign update_PHT_index = pcM[11:2]^GHT_realM;
    
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(PHT[update_PHT_index])
                // 
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Weakly_not_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------初始化和更新PHT----------------------------------

    assign pred_takeD = branchD & pred_takeF_r;  
endmodule
