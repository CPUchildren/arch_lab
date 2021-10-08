module branch_predict_global (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire errorM,         // ��M�׶η����Ƿ��жϴ���

    input wire branchM,         // M�Ƿ��Ƿ�ָ֧��
    input wire actual_takeM,    // �Ƿ������M�׶���ת
    
    input wire branchF,
    input wire branchD,        //   D�׶��Ƿ��Ƿ�ָ֧��  
    output wire pred_takeD      //  �Ƿ���Ҫ��ת
);
    wire pred_takeF;
    reg pred_takeF_r;

// 定义参数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1 : 0];


    reg [(PHT_DEPTH-1):0] GHR;          // Global History Register
    reg [(PHT_DEPTH-1):0] RGHR;         // Repaired GHR
// ---------------------------------------GHR��Ԥ��׶θ���Ԥ��ֵ����------------------------------------
    always@(posedge clk) begin
        if(rst) begin
            GHR <= 0;
        end
        else if(branchF) begin
            GHR <= (GHR<<1) + (pred_takeF & branchF);   // ����Ԥ��ֵ����
        end
        else if(errorM) begin
            GHR[0] <= RGHR[0];
        end
    end
// ---------------------------------------GHR��Ԥ��׶θ���Ԥ��ֵ����------------------------------------



// ----------------------------------Repair GHT����M�׶��Ƿ���ʵ��ת����---------------------------------

    always@(posedge clk) begin
        if(rst) begin
            RGHR <= 0;
        end
        else if(branchM) begin
            RGHR <= (RGHR<<1) + actual_takeM;
        end
    end
// ----------------------------------Repair GHT����M�׶��Ƿ���ʵ��ת����---------------------------------


    integer i,j;

// ---------------------------------------Ԥ�Ȿ��ָ���Ƿ���ת-------------------------------------------
    assign pred_takeF = PHT[GHR][1];      // Ԥ���Ƿ���ת

// --------------------------pipeline-----------------------------
    always @(posedge clk) begin     //�ӳ�һ����
        if(rst | flushD) begin
            pred_takeF_r <= 0;
        end
        else if(~stallD) begin
            pred_takeF_r <= pred_takeF;
        end
    end
// --------------------------pipeline-----------------------------

// ---------------------------------------Ԥ�Ȿ��ָ���Ƿ���ת-------------------------------------------


// ----------------------------------Repair GHT����M�׶��Ƿ���ʵ��ת����---------------------------------

    always@(posedge clk) begin
        if(rst) begin
            RGHR <= 0;
        end
        else if(actual_takeM) begin
            RGHR <= (RGHR<<1) + actual_takeM;
        end
    end
// ----------------------------------Repair GHT����M�׶��Ƿ���ʵ��ת����--------------------------------


// ---------------------------------------PHT初�?化以及更�?---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(PHT[RGHR])
                // 此�?应�?添加你的更新逻辑的代�?
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Weakly_not_taken;
                    end
                    else begin
                        PHT[RGHR] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        PHT[RGHR] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        PHT[RGHR] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        PHT[RGHR] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT初�?化以及更�?---------------------------------------

    // 译码阶�?输出�?终的预测结果
    assign pred_takeD = branchD & pred_takeF_r;  
endmodule