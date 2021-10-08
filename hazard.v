`timescale 1ns/1ps
module hazard (
    input wire regwriteE,regwriteM,regwriteW,memtoRegE,memtoRegM,branchD,
    input wire [4:0]rsD,rtD,rsE,rtE,reg_waddrM,reg_waddrW,reg_waddrE,errorM,
    output wire stallF,stallD,flushE,flushM,forwardAD,forwardBD,
    output wire[1:0] forwardAE, forwardBE
);
    
    // 数据冒险
    assign forwardAE =  ((rsE != 5'b0) & (rsE == reg_waddrM) & regwriteM) ? 2'b10: // 前推计算结果
                        ((rsE != 5'b0) & (rsE == reg_waddrW) & regwriteW) ? 2'b01: // 前推写回结果
                        2'b00; // 原结�?
    assign forwardBE =  ((rtE != 5'b0) & (rtE == reg_waddrM) & regwriteM) ? 2'b10: // 前推计算结果
                        ((rtE != 5'b0) & (rtE == reg_waddrW) & regwriteW) ? 2'b01: // 前推写回结果
                        2'b00; // 原结�? 
    
    // 控制冒险产生的写冲突 
    // 0 原结果， 1 写回结果
    assign forwardAD = (rsD != 5'b0) & (rsD == reg_waddrM) & regwriteM;
    assign forwardBD = (rtD != 5'b0) & (rtD == reg_waddrM) & regwriteM;
    
    // 判断 decode 阶�?? rs �? rt 的地址�?否是上一个lw 指令要写入的地址rtE�?
    wire lwstall,branch_stall; // 指令阻�??
    assign lwstall = ((rsD == rtE) | (rtD == rtE)) & memtoRegE;
    assign branch_stall =   (branchD & regwriteE & ((rsD == reg_waddrE)|(rtD == reg_waddrE))) | // 执�?�阶段阻塞，前面有写入的数据
                            (branchD & memtoRegM & ((rsD == reg_waddrM)|(rtD == reg_waddrM))); // 写回阶�?�阻�?
    
    assign stallF = lwstall | branch_stall;
    assign stallD = lwstall | branch_stall;
    assign flushE = lwstall | branch_stall | errorM;
    assign flushM = errorM;
endmodule