module branch_predict (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,
    
    input wire branchF,
    input wire branchD,        // ����׶��Ƿ�����תָ��   
    input wire branchM,         // M�׶��Ƿ��Ƿ�ָ֧��
    input wire actual_takeM,    // ʵ���Ƿ���ת
    input wire Lpred_takeM,
    input wire Gpred_takeM,
    input wire pred_takeM,
    
    output wire pred_takeD_final,      // Ԥ���Ƿ���ת;������֧Ԥ��Ľ��
    output wire Lpred_takeD,
    output wire Gpred_takeD
);
// ���幫������
    integer i,j;
//    wire Gpred_takeD,Lpred_takeD;
    parameter Strongly_not_taken = 2'b00,Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;
//==================global predict=====================
    wire Gpred_takeF;
    reg Gpred_takeF_r;

// ����ṹ
     reg [(PHT_DEPTH-1):0] GHR;
    reg [1:0] GPHT [(1<<PHT_DEPTH)-1:0];
    wire [(PHT_DEPTH-1):0] GPHT_index;

// ---------------------------------------Ԥ���߼�---------------------------------------
    // ȡָ�׶�
    assign GPHT_index = pcF[(PHT_DEPTH-1):0] ^GHR;
    assign Gpred_takeF = GPHT[GPHT_index][1];      // ��ȡָ�׶�Ԥ���Ƿ����ת����������ˮ�ߴ��ݸ�����׶Ρ�

    // --------------------------pipeline------------------------------
        always @(posedge clk) begin
            // ˢ��
            if(rst | flushD) begin
                Gpred_takeF_r <= 0;
            end
            // ����
            else if(~stallD) begin
                Gpred_takeF_r <=Gpred_takeF;
            end
        end
    // --------------------------pipeline------------------------------

// ---------------------------------------Ԥ���߼�---------------------------------------


// ---------------------------------------GHR��ʼ���Լ�����---------------------------------------
    wire [(PHT_DEPTH-1):0] update_GPHT_index;
    wire [(PHT_DEPTH-1):0] update_GHR;

    always@(posedge clk) begin
        if(rst) begin
                GHR <= 6'b000000;
        end
        else if(branchF) begin     //��Ԥ��׶θ���GHR
            // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
               GHR={GHR[(PHT_DEPTH-2):0],Gpred_takeF};   
        end
    end
    assign update_GPHT_index = pcM[(PHT_DEPTH-1):0] ^GHR;
// ---------------------------------------GHR��ʼ���Լ�����---------------------------------------

// ---------------------------------------Retired GHR--------------------------------------------
    reg [(PHT_DEPTH-1):0] GHR_retired;
        always@(posedge clk) begin
        if(rst) begin
                GHR_retired <= 6'b000000;
        end
        else if(branchM) begin     //��Ԥ��׶θ���GHR
            // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
               GHR_retired={GHR_retired[(PHT_DEPTH-2):0],actual_takeM};   
               if(actual_takeM!=pred_takeM)begin
                    GHR<=GHR_retired;
               end
        end
    end

// ---------------------------------------PHT��ʼ���Լ�����---------------------------------------
    
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                GPHT[i] <= Weakly_taken;
            end
        end
        else if(branchM) begin
            case(GPHT[update_GPHT_index])
                // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
                Strongly_not_taken: GPHT[update_GPHT_index] <= actual_takeM ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken: GPHT[update_GPHT_index] <= actual_takeM ? Weakly_taken : Strongly_not_taken;
                Weakly_taken: GPHT[update_GPHT_index] <= actual_takeM ? Strongly_taken : Weakly_not_taken;
                Strongly_taken: GPHT[update_GPHT_index] <= actual_takeM ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT��ʼ���Լ�����---------------------------------------

    // ����׶�������յ�Ԥ����
    assign Gpred_takeD = branchD & Gpred_takeF_r;  
//==================local predict=====================
    wire Lpred_takeF;
    reg Lpred_takeF_r;
    // ����ṹ
    reg [(PHT_DEPTH-1):0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] LPHT [(1<<PHT_DEPTH)-1:0];
    
//    integer i,j;
    wire [(PHT_DEPTH-1):0] LPHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------Ԥ���߼�---------------------------------------
    // ȡָ�׶�
    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign LPHT_index = pcF[(PHT_DEPTH-1):0] ^ BHR_value;

    assign Lpred_takeF = LPHT[LPHT_index][1];      // ��ȡָ�׶�Ԥ���Ƿ����ת����������ˮ�ߴ��ݸ�����׶Ρ�

    // --------------------------pipeline------------------------------
        always @(posedge clk) begin
            // ˢ��
            if(rst | flushD) begin
                Lpred_takeF_r <= 0;
            end
            // ����
            else if(~stallD) begin
                Lpred_takeF_r <= Lpred_takeF;
            end
        end
    // --------------------------pipeline------------------------------

// ---------------------------------------Ԥ���߼�---------------------------------------


// ---------------------------------------BHT��ʼ���Լ�����---------------------------------------
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
            // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
            BHT[update_BHT_index] = {BHT[update_BHT_index][(PHT_DEPTH-2):0],actual_takeM};
        end
    end
// ---------------------------------------BHT��ʼ���Լ�����---------------------------------------


// ---------------------------------------PHT��ʼ���Լ�����---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                LPHT[i] <= Weakly_taken;
            end
        end
        else if(branchM) begin
            case(LPHT[update_LPHT_index])
                // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
                Strongly_not_taken: LPHT[update_LPHT_index] <= actual_takeM ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken: LPHT[update_LPHT_index] <= actual_takeM ? Weakly_taken : Strongly_not_taken;
                Weakly_taken: LPHT[update_LPHT_index] <= actual_takeM ? Strongly_taken : Weakly_not_taken;
                Strongly_taken: LPHT[update_LPHT_index] <= actual_takeM ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT��ʼ���Լ�����---------------------------------------

    // ����׶�������յ�Ԥ����
    assign Lpred_takeD = branchD & Lpred_takeF_r;  
    //------------------------------�����ķ�֧Ԥ�ⷨ----------------------------------
    wire res_P1,res_P2;   //P1��P2Ԥ������ȷ���
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
                // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
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