`timescale 1ns / 1ps
module datapath (
    input wire clk,rst,    
    input wire [31:0]instrF,data_ram_rdataM,
    
    output wire memWriteM,
    output wire [31:0]instrD,pcF,data_ram_waddrM,data_ram_wdataM
);

// ==================== �����������������ظ����壬���Ǽ�����һ��� =======================
// F
wire stallF,flushF;
wire [31:0]pc_plus4F,pc_nextF;
// D
wire stallD,flushD,forwardAD,forwardBD,Lpred_takeD,Gpred_takeD,pred_takeD,branchD,branchF,jumpD; // pcsrcD
wire [4:0]rtD,rdD,rsD;
wire [31:0]pcD,pc_plus4D,pc_branchD;
wire [31:0]rd1D,rd2D,branch_rd1D,branch_rd2D;
wire [31:0]sl2_instrD,sign_immD,sl2_sign_immD;
// E
wire flushE,actual_takeE,Lpred_takeE,Gpred_takeE,pred_takeE,regdstE,alusrcE,regwriteE,memtoRegE;
wire [1:0]forwardAE,forwardBE;
wire [2:0]alucontrolE;
wire [4:0]rtE,rdE,rsE,reg_waddrE;
wire [31:0]rd1E,rd2E,sel_rd1E,sel_rd2E;
wire [31:0]sign_immE;
wire [31:0]srcB,alu_resE;
wire [31:0]pcE,pc_plus4E,pc_branchE,instrE;
// M
wire flushM,actual_takeM,Lpred_takeM,Gpred_takeM,pred_takeM,branchM,regwriteM,memtoRegM;
wire [4:0]reg_waddrM;
wire [31:0]alu_resM,pcM,pc_plus4M,pc_branchM,pc_actualM,instrM;
// W
wire regwriteW,memtoRegW;
wire [4:0]reg_waddrW;
wire [31:0]wd3W,alu_resW,data_ram_rdataW,instrW;
// other 
wire clear,ena;  // wire zero ==> branch��ת���ƣ��Ѿ�������*����ð��*��

assign clear = 1'b0;
assign ena = 1'b1;

// ====================================== Fetch ======================================
assign branchF=(instrF[31:26]==6'b000100)? 1:0;
pc_mux pc_mux(
    // .flushF(flushF),
    .jumpD(jumpD),
    .branch_takeD(pred_takeD),
    .pc_plus4F(pc_plus4F),
    .pc_branchD(pc_branchD),
    // .pc_actualM(pc_actualM),
    .pc_jumpD({pc_plus4D[31:28],sl2_instrD[27:0]}),

    .pc_nextF(pc_nextF)
);

pc pc(
    .clk(clk),
    .rst(rst),
    .ena(~stallF & ~flushF),
    .flush(flushF),
    .dactual(pc_actualM),
    .din(pc_nextF),
    .dout(pcF)
);
adder adder(
    .a(pcF),
    .b(32'd4),
    .y(pc_plus4F)
);


// ====================================== Decoder ======================================
// ע�⣺����Ҫ��ҪflushD��û���⣬��Ϊ��תָ����涼��һ��nop������û��ϵ
flopenrc #(32) DFF_instrD   (clk,rst,flushD,~stallD,instrF,instrD);
flopenrc #(32) DFF_pc_plus4D(clk,rst,clear ,~stallD,pc_plus4F,pc_plus4D);
flopenrc #(32) DFF_pcD      (clk,rst,flushD,~stallD,pcF,pcD);

controller controller (
    clk,rst,flushE,flushM,
    instrD,
    regwriteW,regdstE,alusrcE,branchD,branchM,memWriteM,memtoRegW,jumpD,
    // ����ð������ź�
    regwriteE,regwriteM,memtoRegE,memtoRegM, // input wire 
    alucontrolE
);

assign rsD = instrD[25:21];
assign rtD = instrD[20:16];
assign rdD = instrD[15:11];

regfile regfile(
	.clk(clk),
	.we3(regwriteW),
	.ra1(instrD[25:21]), 
    .ra2(instrD[20:16]),
    .wa3(reg_waddrW), // ǰin��out
	.wd3(wd3W), 
	.rd1(rd1D),
    .rd2(rd2D)
);

// jumpָ����չ
sl2 sl2_instr(
    .a(instrD),
    .y(sl2_instrD)
);

signext sign_extend(
    .a(instrD[15:0]), // input wire [15:0]a
    .y(sign_immD) // output wire [31:0]y
);

sl2 sl2_signImm(
    .a(sign_immD),
    .y(sl2_sign_immD)
);

adder adder_branch(
    .a(sl2_sign_immD),
    .b(pc_plus4D),
    .y(pc_branchD)
);

// ====================================== Execute ======================================
flopenrc #(32) DFF_pc_branchE(clk,rst,flushE,ena,pc_branchD,pc_branchE);
flopenrc #(32) DFF_pc_plus4E (clk,rst,flushE,ena,pc_plus4D,pc_plus4E);
flopenrc #(32) DFF_instrE    (clk,rst,flushE,ena,instrD,instrE);
flopenrc #(32) DFF_rd1E      (clk,rst,flushE,ena,rd1D,rd1E);
flopenrc #(32) DFF_rd2E      (clk,rst,flushE,ena,rd2D,rd2E);
flopenrc #(32) DFF_sign_immE (clk,rst,flushE,ena,sign_immD,sign_immE);
flopenrc #(32) DFF_pcE       (clk,rst,flushE,ena,pcD,pcE);
flopenrc #(5 ) DFF_rtE       (clk,rst,flushE,ena,rtD,rtE);
flopenrc #(5 ) DFF_rdE       (clk,rst,flushE,ena,rdD,rdE);
flopenrc #(5 ) DFF_rsE       (clk,rst,flushE,ena,rsD,rsE);
flopenrc #(1 ) DFF_Lpred_takeE(clk,rst,flushE,ena,Lpred_takeD,Lpred_takeE);
flopenrc #(1 ) DFF_Gpred_takeE(clk,rst,flushE,ena,Gpred_takeD,Gpred_takeE);
flopenrc #(1 ) DFF_pred_takeE(clk,rst,flushE,ena,pred_takeD,pred_takeE);

mux2 #(5) mux2_regDst(.a(rtE),.b(rdE),.sel(regdstE),.y(reg_waddrE));

alu alu(
    .a(sel_rd1E),
    .b(srcB),
    .f(alucontrolE),
    .y(alu_resE),
    .overflow(),
    .zero() // wire zero ==> branch��ת���ƣ��Ѿ�������*����ð��*��
);

// ֻ���beq����ת�ж�
assign actual_takeE = (sel_rd1E == sel_rd2E) ? 1:0;

// ====================================== Memory ======================================
flopenrc #(32) DFF_pc_branchM     (clk,rst,flushM,ena,pc_branchE,pc_branchM);
flopenrc #(32) DFF_pc_plus4M      (clk,rst,flushM,ena,pc_plus4E,pc_plus4M);
flopenrc #(32) DFF_instrM         (clk,rst,flushM,ena,instrE,instrM);
flopenrc #(32) DFF_actual_takeM   (clk,rst,flushM,ena,actual_takeE,actual_takeM);
flopenrc #(32) DFF_alu_resM       (clk,rst,flushM,ena,alu_resE,alu_resM);
flopenrc #(32) DFF_data_ram_wdataM(clk,rst,flushM,ena,sel_rd2E,data_ram_wdataM);
flopenrc #(32) DFF_pcM            (clk,rst,flushM,ena,pcE,pcM);
flopenrc #(5 ) DFF_reg_waddrM     (clk,rst,flushM,ena,reg_waddrE,reg_waddrM);
flopenrc #(1 ) DFF_Lpred_takeM     (clk,rst,flushM,ena,Lpred_takeE,Lpred_takeM);
flopenrc #(1 ) DFF_Gpred_takeM     (clk,rst,flushM,ena,Gpred_takeE,Gpred_takeM);
flopenrc #(1 ) DFF_pred_takeM     (clk,rst,flushM,ena,pred_takeE,pred_takeM);

assign data_ram_waddrM = alu_resM;
assign pc_actualM = actual_takeM ? pc_branchM : pc_plus4M;

// ====================================== WriteBack ======================================
flopenrc #(32) DFF_instrW         (clk,rst,clear,ena,instrM,instrW);
flopenrc #(32) DFF_alu_resW       (clk,rst,clear,ena,alu_resM,alu_resW);
flopenrc #(32) DFF_data_ram_rdataW(clk,rst,clear,ena,data_ram_rdataM,data_ram_rdataW);
flopenrc #(5 ) DFF_reg_waddrW     (clk,rst,clear,ena,reg_waddrM,reg_waddrW);

mux2 mux2_memtoReg(.a(alu_resW),.b(data_ram_rdataW),.sel(memtoRegW),.y(wd3W));


// ******************* �������ӳٷ�����֧��ǰ *****************
// �� regfile ��������һ���ж���ȵ�ģ�飬������ǰ�ж� beq���Խ���ָ֧����ǰ��Decode�׶Σ�Ԥ�⣩
// mux2 mux2_forwardAD(rd1D,alu_resM,forwardAD,branch_rd1D);
// mux2 mux2_forwardBD(rd2D,alu_resM,forwardBD,branch_rd2D);
// assign actual_takeM = (branch_rd1D == branch_rd2D) ? 1:0;
// assign pcsrcD = actual_takeM & branchD;

// *******************���ֲ���ʷ����̬��֧Ԥ�� *******************
// ��FԤ���Ƿ���ת��
// ��Dִ��Ԥ������
// ��E�ж��Ƿ�Ԥ����ȷ��
// ��M�������Ԥ��͸���PHT��
branch_predict branch_predict(
    .clk(clk),  // input wire  
    .rst(rst),  // input wire 
    .flushD(flushD),  // input wire 
    .branchF(branchF),
    .stallD(stallD),  // input wire 
    .pcF(pcF),  // input wire [31:0] 
    .pcM(pcM),  // input wire [31:0] 
    .branchD(branchD),  // output wire              // ����׶��Ƿ�����תָ��   
    .branchM(branchM),  // input wire               // M�׶��Ƿ��Ƿ�ָ֧��
    .actual_takeM(actual_takeM),  // input wire     // ʵ���Ƿ���ת
    .Lpred_takeM(Lpred_takeM),
    .Gpred_takeM(Gpred_takeM),
    .pred_takeD_final(pred_takeD),   // output wire        // Ԥ���Ƿ���ת
    .Lpred_takeD(Lpred_takeD),
    .Gpred_takeD(Gpred_takeD)
);

// ******************* ������ð�ա�ALU���� *****************
// 00ԭ�����01д�ؽ��_W�� 10������_M
mux3 #(32) mux3_forwardAE(rd1E,wd3W,alu_resM,forwardAE,sel_rd1E);
mux3 #(32) mux3_forwardBE(rd2E,wd3W,alu_resM,forwardBE,sel_rd2E);
mux2 mux2_aluSrc(.a(sel_rd2E),.b(sign_immE),.sel(alusrcE),.y(srcB));

// ******************* ð���ź��ܿ��� *****************
hazard hazard (
    regwriteE,regwriteM,regwriteW,
    memtoRegE,memtoRegM,
    branchM,actual_takeM,pred_takeM,
    rsD,rtD,rsE,rtE,
    reg_waddrM,reg_waddrW,reg_waddrE,
    
    stallF,stallD,
    flushF,flushD,flushE,flushM,
    forwardAD,forwardBD,
    forwardAE, forwardBE
);

// instdec
instdec instdecF(instrF);
instdec instdecD(instrD);
instdec instdecE(instrE);
instdec instdecM(instrM);
instdec instdecW(instrW);
endmodule