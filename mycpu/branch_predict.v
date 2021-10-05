module branch_predict (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,
    
    input wire branchD,        // ����׶��Ƿ�����תָ��   
    input wire branchM,         // M�׶��Ƿ��Ƿ�ָ֧��
    input wire actual_takeM,    // ʵ���Ƿ���ת

    
    output wire pred_takeD      // Ԥ���Ƿ���ת
);
    wire pred_takeF;
    reg pred_takeF_r;

// �������
    parameter Strongly_not_taken = 2'b00,Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;

// ����ṹ
    reg [(PHT_DEPTH-1):0] GHT;
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;

// ---------------------------------------Ԥ���߼�---------------------------------------
    // ȡָ�׶�
    assign PHT_index = pcF[(PHT_DEPTH-1):0] ^ GHT[(PHT_DEPTH-1):0];

    assign pred_takeF = PHT[PHT_index][1];      // ��ȡָ�׶�Ԥ���Ƿ����ת����������ˮ�ߴ��ݸ�����׶Ρ�

    // --------------------------pipeline------------------------------
    always @(posedge clk) begin
        // ˢ��
        if(rst | flushD) begin
            pred_takeF_r <= 0;
        end
        // ����
        else if(~stallD) begin
            pred_takeF_r <= pred_takeF;
        end
    end
    // --------------------------pipeline------------------------------

// ---------------------------------------Ԥ���߼�---------------------------------------


// ---------------------------------------GHT��ʼ���Լ�����---------------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    assign update_PHT_index = pcM[(PHT_DEPTH-1):0] ^ GHT;

    always@(posedge clk) begin
        if(rst) begin
            GHT <= 6'b000000;
        end
        else if(branchM) begin
            // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
            GHT = {GHT[(PHT_DEPTH-2):0],actual_takeM};
        end
    end
// ---------------------------------------GHT��ʼ���Լ�����---------------------------------------


// ---------------------------------------PHT��ʼ���Լ�����---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else if(branchM) begin
            case(PHT[update_PHT_index])
                // ********** �˴�Ӧ�������ĸ����߼��Ĵ��� **********
                Strongly_not_taken: PHT[update_PHT_index] <= actual_takeM ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken: PHT[update_PHT_index] <= actual_takeM ? Weakly_taken : Strongly_not_taken;
                Weakly_taken: PHT[update_PHT_index] <= actual_takeM ? Strongly_taken : Weakly_not_taken;
                Strongly_taken: PHT[update_PHT_index] <= actual_takeM ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT��ʼ���Լ�����---------------------------------------

    // ����׶�������յ�Ԥ����
    assign pred_takeD = branchD & pred_takeF_r;  
endmodule