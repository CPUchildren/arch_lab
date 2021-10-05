module branch_predict (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,
    
    input wire branchD,        // 译码阶段是否是跳转指令   
    input wire branchM,         // M阶段是否是分支指令
    input wire actual_takeM,    // 实际是否跳转

    
    output wire pred_takeD      // 预测是否跳转
);
    wire pred_takeF;
    reg pred_takeF_r;

// 定义参数
    parameter Strongly_not_taken = 2'b00,Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;

// 定义结构
    reg [(PHT_DEPTH-1):0] GHT;
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;

// ---------------------------------------预测逻辑---------------------------------------
    // 取指阶段
    assign PHT_index = pcF[(PHT_DEPTH-1):0] ^ GHT[(PHT_DEPTH-1):0];

    assign pred_takeF = PHT[PHT_index][1];      // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段。

    // --------------------------pipeline------------------------------
    always @(posedge clk) begin
        // 刷新
        if(rst | flushD) begin
            pred_takeF_r <= 0;
        end
        // 阻塞
        else if(~stallD) begin
            pred_takeF_r <= pred_takeF;
        end
    end
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
                PHT[i] <= Weakly_taken;
            end
        end
        else if(branchM) begin
            case(PHT[update_PHT_index])
                // ********** 此处应该添加你的更新逻辑的代码 **********
                Strongly_not_taken: PHT[update_PHT_index] <= actual_takeM ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken: PHT[update_PHT_index] <= actual_takeM ? Weakly_taken : Strongly_not_taken;
                Weakly_taken: PHT[update_PHT_index] <= actual_takeM ? Strongly_taken : Weakly_not_taken;
                Strongly_taken: PHT[update_PHT_index] <= actual_takeM ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

    // 译码阶段输出最终的预测结果
    assign pred_takeD = branchD & pred_takeF_r;  
endmodule