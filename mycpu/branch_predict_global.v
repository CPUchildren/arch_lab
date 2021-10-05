`include "defines.vh"
module branch_predict_global #(parameter PHT_DEPTH = 6) // 作为端口参数
(
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,
    input wire flushE,
    input wire flushM,

    input wire [31:0] pcF,
    input wire [31:0] pcM,
    
    input wire branchD,        // 译码阶段是否是跳转指令   
    input wire branchM,         // M阶段是否是分支指令
    input wire actual_takeM,    // 实际是否跳转

    output wire [(PHT_DEPTH-1):0] PHT_index, // 输出，作为CPHT的索引
    output wire [(PHT_DEPTH-1):0] update_PHT_index, // 输出，作为CPHT的索引
    output wire pred_takeD,      // 预测是否跳转
    output wire correct          // 预测是否正确
);
// 定义参数
    wire clear,ena;  // wire zero ==> branch跳转控制（已经升级到*控制冒险*）
    assign clear = 1'b0;
    assign ena = 1'b1;

    wire predF,predD,predE,predM;
    wire pred_takeM;
// 定义结构
    reg [(PHT_DEPTH-1):0] GHT;
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;

// ---------------------------------------预测逻辑---------------------------------------
    // 取指阶段
    assign PHT_index = pcF[(PHT_DEPTH-1):0] ^ GHT[(PHT_DEPTH-1):0];

    assign predF = PHT[PHT_index][1];      // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段。

    // --------------------------pipeline------------------------------
    flopenrc #(1) DFF_predD(clk,rst,flushD,~stallD,predF,predD);
    flopenrc #(1) DFF_predE(clk,rst,flushE,ena,predD,predE);
    flopenrc #(1) DFF_predM(clk,rst,flushM,ena,predE,predM);
    // --------------------------pipeline------------------------------

// ---------------------------------------预测逻辑---------------------------------------


// ---------------------------------------GHT初始化以及更新---------------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    assign update_PHT_index = pcM[(PHT_DEPTH-1):0] ^ GHT;

    always@(posedge clk) begin
        if(rst) begin
            GHT <= 6'b000000;
        end
        else if(branchM) begin
            // ********** 此处应该添加你的更新逻辑的代码 **********
            GHT = {GHT[(PHT_DEPTH-2):0],actual_takeM};
        end
    end
// ---------------------------------------GHT初始化以及更新---------------------------------------


// ---------------------------------------PHT初始化以及更新---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= `Weakly_taken;
            end
        end
        else if(branchM) begin
            case(PHT[update_PHT_index])
                // ********** 此处应该添加你的更新逻辑的代码 **********
                `Strongly_not_taken: PHT[update_PHT_index] <= actual_takeM ? `Weakly_not_taken : `Strongly_not_taken;
                `Weakly_not_taken  : PHT[update_PHT_index] <= actual_takeM ? `Weakly_taken     : `Strongly_not_taken;
                `Weakly_taken      : PHT[update_PHT_index] <= actual_takeM ? `Strongly_taken   : `Weakly_not_taken  ;
                `Strongly_taken    : PHT[update_PHT_index] <= actual_takeM ? `Strongly_taken   : `Weakly_taken      ;
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

    // 译码阶段输出最终的预测结果
    assign pred_takeD = branchD & predD;
    assign pred_takeM = branchM & predM;  
    assign correct = (actual_takeM  == pred_takeM)?1:0;
endmodule