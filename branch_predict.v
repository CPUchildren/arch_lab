module branch_predict (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,
    
    input wire branchF,
    input wire branchD,        // 译码阶段是否是跳转指令   
    input wire branchM,         // M阶段是否是分支指令
    input wire actual_takeM,    // 实际是否跳转
    input wire Lpred_takeM,
    input wire Gpred_takeM,
    input wire pred_takeM,
    
    output wire pred_takeD_final,      // 预测是否跳转;竞争分支预测的结果
    output wire Lpred_takeD,
    output wire Gpred_takeD
);
// 定义公共参数
    integer i,j;
//    wire Gpred_takeD,Lpred_takeD;
    parameter Strongly_not_taken = 2'b00,Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;
//==================global predict=====================
    wire Gpred_takeF;
    reg Gpred_takeF_r;

// 定义结构
     reg [(PHT_DEPTH-1):0] GHR;
    reg [1:0] GPHT [(1<<PHT_DEPTH)-1:0];
    wire [(PHT_DEPTH-1):0] GPHT_index;

// ---------------------------------------预测逻辑---------------------------------------
    // 取指阶段
    assign GPHT_index = pcF[(PHT_DEPTH-1):0] ^GHR;
    assign Gpred_takeF = GPHT[GPHT_index][1];      // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段。

    // --------------------------pipeline------------------------------
        always @(posedge clk) begin
            // 刷新
            if(rst | flushD) begin
                Gpred_takeF_r <= 0;
            end
            // 阻塞
            else if(~stallD) begin
                Gpred_takeF_r <=Gpred_takeF;
            end
        end
    // --------------------------pipeline------------------------------

// ---------------------------------------预测逻辑---------------------------------------


// ---------------------------------------GHR初始化以及更新---------------------------------------
    wire [(PHT_DEPTH-1):0] update_GPHT_index;
    wire [(PHT_DEPTH-1):0] update_GHR;

    always@(posedge clk) begin
        if(rst) begin
                GHR <= 6'b000000;
        end
        else if(branchF) begin     //在预测阶段更新GHR
            // ********** 此处应该添加你的更新逻辑的代码 **********
               GHR={GHR[(PHT_DEPTH-2):0],Gpred_takeF};   
        end
    end
    assign update_GPHT_index = pcM[(PHT_DEPTH-1):0] ^GHR;
// ---------------------------------------GHR初始化以及更新---------------------------------------

// ---------------------------------------Retired GHR--------------------------------------------
    reg [(PHT_DEPTH-1):0] GHR_retired;
        always@(posedge clk) begin
        if(rst) begin
                GHR_retired <= 6'b000000;
        end
        else if(branchM) begin     //在预测阶段更新GHR
            // ********** 此处应该添加你的更新逻辑的代码 **********
               GHR_retired={GHR_retired[(PHT_DEPTH-2):0],actual_takeM};   
               if(actual_takeM!=pred_takeM)begin
                    GHR<=GHR_retired;
               end
        end
    end

// ---------------------------------------PHT初始化以及更新---------------------------------------
    
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                GPHT[i] <= Weakly_taken;
            end
        end
        else if(branchM) begin
            case(GPHT[update_GPHT_index])
                // ********** 此处应该添加你的更新逻辑的代码 **********
                Strongly_not_taken: GPHT[update_GPHT_index] <= actual_takeM ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken: GPHT[update_GPHT_index] <= actual_takeM ? Weakly_taken : Strongly_not_taken;
                Weakly_taken: GPHT[update_GPHT_index] <= actual_takeM ? Strongly_taken : Weakly_not_taken;
                Strongly_taken: GPHT[update_GPHT_index] <= actual_takeM ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

    // 译码阶段输出最终的预测结果
    assign Gpred_takeD = branchD & Gpred_takeF_r;  
//==================local predict=====================
    wire Lpred_takeF;
    reg Lpred_takeF_r;
    // 定义结构
    reg [(PHT_DEPTH-1):0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] LPHT [(1<<PHT_DEPTH)-1:0];
    
//    integer i,j;
    wire [(PHT_DEPTH-1):0] LPHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------预测逻辑---------------------------------------
    // 取指阶段
    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign LPHT_index = pcF[(PHT_DEPTH-1):0] ^ BHR_value;

    assign Lpred_takeF = LPHT[LPHT_index][1];      // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段。

    // --------------------------pipeline------------------------------
        always @(posedge clk) begin
            // 刷新
            if(rst | flushD) begin
                Lpred_takeF_r <= 0;
            end
            // 阻塞
            else if(~stallD) begin
                Lpred_takeF_r <= Lpred_takeF;
            end
        end
    // --------------------------pipeline------------------------------

// ---------------------------------------预测逻辑---------------------------------------


// ---------------------------------------BHT初始化以及更新---------------------------------------
    wire [(PHT_DEPTH-1):0] update_LPHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign update_BHT_index = pcM[11:2];     
    assign update_BHR_value = BHT[update_BHT_index];  
    assign update_LPHT_index = pcM[(PHT_DEPTH-1):0] ^ update_BHR_value;

    always@(posedge clk) begin
        if(rst) begin
            for(j = 0; j < (1<<BHT_DEPTH); j=j+1) begin
                BHT[j] <= 6'b000000;
            end
        end
        else if(branchM) begin
            // ********** 此处应该添加你的更新逻辑的代码 **********
            BHT[update_BHT_index] = {BHT[update_BHT_index][(PHT_DEPTH-2):0],actual_takeM};
        end
    end
// ---------------------------------------BHT初始化以及更新---------------------------------------


// ---------------------------------------PHT初始化以及更新---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                LPHT[i] <= Weakly_taken;
            end
        end
        else if(branchM) begin
            case(LPHT[update_LPHT_index])
                // ********** 此处应该添加你的更新逻辑的代码 **********
                Strongly_not_taken: LPHT[update_LPHT_index] <= actual_takeM ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken: LPHT[update_LPHT_index] <= actual_takeM ? Weakly_taken : Strongly_not_taken;
                Weakly_taken: LPHT[update_LPHT_index] <= actual_takeM ? Strongly_taken : Weakly_not_taken;
                Strongly_taken: LPHT[update_LPHT_index] <= actual_takeM ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

    // 译码阶段输出最终的预测结果
    assign Lpred_takeD = branchD & Lpred_takeF_r;  
    //------------------------------竞争的分支预测法----------------------------------
    wire res_P1,res_P2;   //P1。P2预测结果正确与否
//    wire pred_takeF;
//    reg pred_takeF_r;
    reg [1:0] CPHT [(1<<PHT_DEPTH)-1:0];
    wire [(PHT_DEPTH-1):0] CPHT_index;
    wire res_sel;
    parameter Strongly_P1 = 2'b00,Weakly_P1 = 2'b01, Strongly_P2 = 2'b11, Weakly_P2 = 2'b10;
    
    
    assign CPHT_index = GPHT_index;
    assign res_sel = CPHT[CPHT_index][1];   //0 for P1    1 for P2
    
    assign res_P1 = (actual_takeM == Gpred_takeM)? 1:0;
    assign res_P2 = (actual_takeM == Lpred_takeM)? 1:0;
    
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                CPHT[i] <= Strongly_P1;
            end
        end
        else if(branchM) begin
            case(CPHT[update_GPHT_index])
                // ********** 此处应该添加你的更新逻辑的代码 **********
                Strongly_P1: GPHT[update_GPHT_index] <= !res_P1 && res_P2 ? Weakly_P1 : Strongly_P1;
                Weakly_P1: GPHT[update_GPHT_index] <= res_P1 && !res_P2 ? Strongly_P1 : 
                                                     !res_P1 && res_P2 ?  Weakly_P2: Weakly_P1;
                Weakly_P1: GPHT[update_GPHT_index] <= res_P1 && !res_P2 ? Weakly_P1 : 
                                                     !res_P1 && res_P2 ?  Strongly_P2: Weakly_P2;
                Strongly_P2: GPHT[update_GPHT_index] <= res_P1 && !res_P2 ? Weakly_P2 : Strongly_P2;
            endcase 
        end
    end
    assign pred_takeD_final = res_sel? Gpred_takeD : Lpred_takeD;
endmodule