`timescale 1ns/1ps
module hazard (
    input wire regwriteE,regwriteM,regwriteW,
    input wire memtoRegE,memtoRegM,
    input wire branchM,actual_takeM,pred_takeM,
    input wire [4:0]rsD,rtD,rsE,rtE,
    input wire [4:0]reg_waddrM,reg_waddrW,reg_waddrE,
    
    output wire stallF,stallD,
    output wire flushF,flushD,flushE,flushM,
    output wire forwardAD,forwardBD,
    output wire[1:0] forwardAE, forwardBE
);
    
    // ����ð��
    assign forwardAE =  ((rsE != 5'b0) & (rsE == reg_waddrM) & regwriteM) ? 2'b10: // ǰ�Ƽ�����
                        ((rsE != 5'b0) & (rsE == reg_waddrW) & regwriteW) ? 2'b01: // ǰ��д�ؽ��
                        2'b00; // ԭ���
    assign forwardBE =  ((rtE != 5'b0) & (rtE == reg_waddrM) & regwriteM) ? 2'b10: // ǰ�Ƽ�����
                        ((rtE != 5'b0) & (rtE == reg_waddrW) & regwriteW) ? 2'b01: // ǰ��д�ؽ��
                        2'b00; // ԭ��� 
    
    // ����ð�ղ�����д��ͻ 
    // 0 ԭ����� 1 д�ؽ��
    assign forwardAD = (rsD != 5'b0) & (rsD == reg_waddrM) & regwriteM;
    assign forwardBD = (rtD != 5'b0) & (rtD == reg_waddrM) & regwriteM;
    
    // �ж� decode �׶� rs �� rt �ĵ�ַ�Ƿ�����һ��lw ָ��Ҫд��ĵ�ַrtE��
    wire lwstall,branch_stall; 
    assign lwstall = ((rsD == rtE) | (rtD == rsE)) & memtoRegE;
    assign branch_stall = branchM & (actual_takeM != pred_takeM);
    
    assign stallF = lwstall | branch_stall;
    assign stallD = lwstall | branch_stall;
    assign flushF = branch_stall; // flushF ��̬��֧Ԥ�����
    assign flushD = branch_stall; // lwstall | 
    assign flushE = lwstall | branch_stall;
    assign flushM = branch_stall; // lwstall | 

endmodule