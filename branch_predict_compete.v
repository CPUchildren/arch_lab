module branch_predict_compete (
    input wire clk, rst,
    
    input wire [31:0] pcF,
    input wire [31:0] pcM,
    input wire flushD,
    input wire stallD,

    input wire errorM,         // ��M�׶η����Ƿ��жϴ���

    input wire branchM,         // M�Ƿ��Ƿ�ָ֧��
    input wire actual_takeM,    // �Ƿ������M�׶���ת
    
    input wire branchF,
    input wire branchD,        //   D�׶��Ƿ��Ƿ�ָ֧��  
    output wire  pred_takeD      //  �Ƿ���Ҫ��ת
);
    wire Gpred_takeF;
    reg Gpred_takeF_r;

    wire Gpred_takeD;
    wire Bpred_takeD;
    wire clear,ena;
    assign clear = 1'b0;
    assign ena = 1'b1;


// ???????????��
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

    reg [1:0] GPHT [(1<<PHT_DEPTH)-1 : 0];

    reg [(PHT_DEPTH-1):0] GHR;          // Global History Register
    reg [(PHT_DEPTH-1):0] RGHR;         // Repaired GHR
// ---------------------------------------GHR��Ԥ��׶θ���Ԥ��ֵ����------------------------------------
    always@(posedge clk) begin
        if(rst) begin
            GHR <= 0;
        end
        else if(branchF) begin
            GHR <= (GHR<<1) + (Gpred_takeF & branchF);   // ����Ԥ��ֵ����
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
    assign Gpred_takeF = GPHT[GHR][1];      // Ԥ���Ƿ���ת

// --------------------------pipeline-----------------------------
    always @(posedge clk) begin     //�ӳ�һ����
        if(rst | flushD) begin
            Gpred_takeF_r <= 0;
        end
        else if(~stallD) begin
            Gpred_takeF_r <= Gpred_takeF;
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
                GPHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(GPHT[RGHR])
                // 此�?应�?添加你的更新逻辑的代�?
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Weakly_not_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT初�?化以及更�?---------------------------------------

    // 译码阶�?输出�?终的预测结果
    assign Gpred_takeD = branchD & Gpred_takeF_r;  

////////////////////////////////////////////////////�ֽ���////// ��global   ��local


    wire Bpred_takeF;
    reg Bpred_takeF_r;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] BPHT [(1<<PHT_DEPTH)-1:0];
    
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------��?????��?????---------------------------------------

    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;
    
    assign Bpred_takeF = BPHT[PHT_index][1];      // ??��??????��?????��??????????????��????????????????????��???????��???????????��???????
    
        // --------------------------pipeline------------------------------
            always @(posedge clk) begin
                if(rst | flushD) begin
                    Bpred_takeF_r <= 0;
                end
                else if(~stallD) begin
                    Bpred_takeF_r <= Bpred_takeF;
                end
            end
        // --------------------------pipeline------------------------------

// ---------------------------------------��?????��?????---------------------------------------


// ---------------------------------------BHT????????????????????---------------------------------------
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
            // ??��????????��???????????????�㨦??????????????
            if(actual_takeM) begin
                BHT[update_BHT_index] <= (update_BHR_value<<1)+1;
            end
            else begin
                BHT[update_BHT_index] <= (update_BHR_value<<1);
            end
        end
    end

// ---------------------------------------BHT????????????????????---------------------------------------


// ---------------------------------------PHT????????????????????---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                BPHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(BPHT[update_PHT_index])
                // ??��????????��???????????????�㨦??????????????
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Weakly_not_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT????????????????????---------------------------------------

    // ??????��???????????????????��???????????
    assign Bpred_takeD = branchD & Bpred_takeF_r;


    wire Gpred_takeE,Gpred_takeM;
    wire Bpred_takeE,Bpred_takeM;


    flopenrc #(1) GpreE(clk,rst,clear,ena,Gpred_takeD,Gpred_takeE);
    flopenrc #(1) GpreM(clk,rst,clear,ena,Gpred_takeE,Gpred_takeM);

    flopenrc #(1) BpreE(clk,rst,clear,ena,Bpred_takeD,Bpred_takeE);
    flopenrc #(1) BpreM(clk,rst,clear,ena,Bpred_takeE,Bpred_takeM);

    wire Gcorr,Bcorr;
    assign Gcorr = Gpred_takeM & actual_takeM;
    assign Bcorr = Bpred_takeM & actual_takeM;

    wire sigs;
    assign sigs={Gcorr,Bcorr};
    

//////// CPHT
    reg [2:0] CPHT [ (1<<BHT_DEPTH)-1 : 0];
    wire CPHT_index;
    assign CPHT_index = pcM[11:2];   

    parameter Strongly_global = 2'b00, Weakly_global = 2'b01, Weakly_local = 2'b10, Strongly_local = 2'b11;

    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<BHT_DEPTH); i=i+1) begin
                CPHT[i] <= Strongly_global;
            end
        end
        else begin
            case(CPHT[CPHT_index])
                // ??��????????��???????????????�㨦??????????????
                Strongly_global:begin
                    if(sigs==2'b00 || sigs==2'b11 || sigs==2'b10) begin
                        CPHT[CPHT_index] <= Strongly_global;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_global;
                    end
                end
                Weakly_global:begin
                    if(sigs==2'b10) begin
                        CPHT[CPHT_index] <= Strongly_global;
                    end
                    else if(sigs==2'b01) begin
                        CPHT[CPHT_index] <= Weakly_local;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_global;
                    end
                end
                Weakly_local:begin
                    if(sigs==2'b10) begin
                        CPHT[CPHT_index] <= Weakly_global;
                    end
                    else if(sigs==2'b01) begin
                        CPHT[CPHT_index] <= Strongly_local;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_local;
                    end
                end
                Strongly_local:begin
                    if(sigs==2'b00 || sigs==2'b11 || sigs==2'b01) begin
                        CPHT[CPHT_index] <= Strongly_local;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_local;
                    end
                end



            endcase 
        end
    end

    wire pred_chooseF,pred_chooseD;
    assign pred_chooseF=CPHT[pcF[11:2]][1];
    flopenrc #(1) prechoose(clk,rst,clear,ena,pred_chooseF,pred_chooseD);
    
    assign pred_takeD= (pred_chooseD==1'b0)?Gpred_takeD:Bpred_takeD;

endmodule