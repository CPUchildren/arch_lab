module branch_predict (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,

    input wire branchM,         // M阶段是否是分支指�?
    input wire actual_takeM,    // 实际是否跳转

    input wire branchD,        // 译码阶段是否是跳转指�?   
    output wire pred_takeD      // 预测是否跳转
);
    wire pred_takeF;
    reg pred_takeF_r;
    // assign branchD = (instrD[31:26]==000100 || instrD[31:26]==000101 || instrD[31:26]==000001 || instrD[31:26]==000111 || instrD[31:26]==000110)?1:0;//判断译码阶段是否是分支指�?

// 定义参数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------预测逻辑---------------------------------------

    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;

    assign pred_takeF = PHT[PHT_index][1];      // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段�?

        // --------------------------pipeline------------------------------
            always @(posedge clk) begin
                if(rst | flushD) begin
                    pred_takeF_r <= 0;
                end
                else if(~stallD) begin
                    pred_takeF_r <= pred_takeF;
                end
            end
        // --------------------------pipeline------------------------------

// ---------------------------------------预测逻辑---------------------------------------


// ---------------------------------------BHT初始化以及更�?---------------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign update_BHT_index = pcM[11:2];     
    assign update_BHR_value = BHT[update_BHT_index];  
    assign update_PHT_index = update_BHR_value;

    always@(posedge clk) begin
        if(rst) begin
            for(j = 0; j < (1<<BHT_DEPTH); j=j+1) begin
                BHT[j] <= 0;
            end
        end
        else if(branchM) begin
            // 此处应该添加你的更新逻辑的代�?
            if(actual_takeM) begin
                BHT[update_BHT_index] <= (update_BHR_value<<1)+1;
            end
            else begin
                BHT[update_BHT_index] <= (update_BHR_value<<1);
            end
        end
    end
// ---------------------------------------BHT初始化以及更�?---------------------------------------


// ---------------------------------------PHT初始化以及更�?---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(PHT[update_PHT_index])
                // 此处应该添加你的更新逻辑的代�?
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
// ---------------------------------------PHT初始化以及更�?---------------------------------------

    // 译码阶段输出�?终的预测结果
    assign pred_takeD = branchD & pred_takeF_r;  
endmodule