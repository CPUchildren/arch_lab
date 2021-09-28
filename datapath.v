`timescale 1ns / 1ps
module datapath (
    input wire clk,rst,
    input wire regwriteW,regdstE,alusrcE,branchD,memWriteM,memtoRegW,jumpD,
    input wire [2:0]alucontrolE,
    // 数据冒险添加信号
    input wire regwriteE,regwriteM,memtoRegE,memtoRegM,
    input wire [31:0]instrF,data_ram_rdataM,
    output wire [31:0]instrD,pc_now,data_ram_waddr,data_ram_wdataM
);

// ==================== 变量定义区，避免重复定义，还是集中在一起吧 =======================
wire pcsrcD,clear,ena,equalD; // wire zero ==> branch跳转控制（已经升级到*控制冒险*）
wire stallF,stallD,flushD,flushE,forwardAD,forwardBD;
wire [1:0]forwardAE,forwardBE;
wire [4:0]rtD,rdD,rsD,rtE,rdE,rsE;
wire [4:0]reg_waddrE,reg_waddrM,reg_waddrW;
wire [31:0]pc_plus4F,pc_plus4D,pc_branchD,pc_next,pc_next_jump;
wire [31:0]rd1D,rd2D,rd1E,rd2E,wd3W,rd1D_branch,rd2D_branch,sel_rd1E,sel_rd2E;
wire [31:0]instrD_sl2,sign_immD,sign_immE,sign_immD_sl2;
wire [31:0]srcB,alu_resE,alu_resM,alu_resW,data_ram_rdataW;

assign clear = 1'b0;
assign ena = 1'b1;
assign flushD = pcsrcD | jumpD;
// ====================================== Fetch ======================================
mux2 mux2_branch(.a(pc_plus4F),.b(pc_branchD),.sel(pcsrcD),.y(pc_next)); // 注意，这里是PC_next是沿用的pc_plus4F

mux2 mux2_jump(
    .a(pc_next),
    .b({pc_plus4D[31:28],instrD_sl2[27:0]}), // 注意，这里是D阶段执行的pc_plus4D
    .sel(jumpD),
    .y(pc_next_jump)
);

pc pc(
    .clk(clk),
    .rst(rst),
    .ena(~stallF),
    .din(pc_next_jump),
    .dout(pc_now)
);

adder adder(
    .a(pc_now),
    .b(32'd4),
    .y(pc_plus4F)
);

// ====================================== Decoder ======================================
// 注意：这里要不要flushD都没问题，因为跳转指令后面都是一个nop，所以没关系
flopenrc DFF_instrD(clk,rst,flushD,~stallD,instrF,instrD);
flopenrc DFF_pc_plus4D(clk,rst,clear,~stallD,pc_plus4F,pc_plus4D);

assign rsD = instrD[25:21];
assign rtD = instrD[20:16];
assign rdD = instrD[15:11];

regfile regfile(
	.clk(clk),
	.we3(regwriteW),
	.ra1(instrD[25:21]), 
    .ra2(instrD[20:16]),
    .wa3(reg_waddrW), // 前in后out
	.wd3(wd3W), 
	.rd1(rd1D),
    .rd2(rd2D)
);

// jump指令拓展
sl2 sl2_instr(
    .a(instrD),
    .y(instrD_sl2)
);

signext sign_extend(
    .a(instrD[15:0]), // input wire [15:0]a
    .y(sign_immD) // output wire [31:0]y
);

sl2 sl2_signImm(
    .a(sign_immD),
    .y(sign_immD_sl2)
);

adder adder_branch(
    .a(sign_immD_sl2),
    .b(pc_plus4D),
    .y(pc_branchD)
);

// ******************* 控制冒险 *****************
// 在 regfile 输出后添加一个判断相等的模块，即可提前判断 beq，以将分支指令提前到Decode阶段（预测）
mux2 mux2_forwardAD(rd1D,alu_resM,forwardAD,rd1D_branch);
mux2 mux2_forwardBD(rd2D,alu_resM,forwardBD,rd2D_branch);
// assign equalD = (rd1D_branch == rd2D_branch);
assign equalD = (rd1D_branch == rd2D_branch) ? 1:0;
assign pcsrcD = equalD & branchD;

// ====================================== Execute ======================================

flopenrc DFF_rd1E(clk,rst,flushE,ena,rd1D,rd1E);
flopenrc DFF_rd2E(clk,rst,flushE,ena,rd2D,rd2E);
flopenrc DFF_sign_immE(clk,rst,flushE,ena,sign_immD,sign_immE);
flopenrc #(5) DFF_rtE(clk,rst,flushE,ena,rtD,rtE);
flopenrc #(5) DFF_rdE(clk,rst,flushE,ena,rdD,rdE);
flopenrc #(5) DFF_rsE(clk,rst,flushE,ena,rsD,rsE);

mux2 #(5) mux2_regDst(.a(rtE),.b(rdE),.sel(regdstE),.y(reg_waddrE));

// ******************* 数据冒险 *****************
// 00原结果，01写回结果_W， 10计算结果_M
mux3 #(32) mux3_forwardAE(rd1E,wd3W,alu_resM,forwardAE,sel_rd1E);
mux3 #(32) mux3_forwardBE(rd2E,wd3W,alu_resM,forwardBE,sel_rd2E);
mux2 mux2_aluSrc(.a(sel_rd2E),.b(sign_immE),.sel(alusrcE),.y(srcB));

alu alu(
    .a(sel_rd1E),
    .b(srcB),
    .f(alucontrolE),
    .y(alu_resE),
    .overflow(),
    .zero() // wire zero ==> branch跳转控制（已经升级到*控制冒险*）
);

// ====================================== Memory ======================================
flopenrc DFF_alu_resM(clk,rst,clear,ena,alu_resE,alu_resM);
flopenrc DFF_data_ram_wdataM(clk,rst,clear,ena,sel_rd2E,data_ram_wdataM);
flopenrc #(5) DFF_reg_waddrM(clk,rst,clear,ena,reg_waddrE,reg_waddrM);
// flopenrc #(1) DFF_zeroM(clk,rst,clear,ena,zero,zeroM);  ==> 控制冒险，已将分支指令提前到Decode阶段

assign data_ram_waddr = alu_resM;
// assign pcsrcM = zeroM & branchM;  ==> 控制冒险，已将分支指令提前到Decode阶段

// ====================================== WriteBack ======================================
flopenrc DFF_alu_resW(clk,rst,clear,ena,alu_resM,alu_resW);
flopenrc DFF_data_ram_rdataW(clk,rst,clear,ena,data_ram_rdataM,data_ram_rdataW);
flopenrc #(5) DFF_reg_waddrW(clk,rst,clear,ena,reg_waddrM,reg_waddrW);

mux2 mux2_memtoReg(.a(alu_resW),.b(data_ram_rdataW),.sel(memtoRegW),.y(wd3W));

// ******************* 冒险信号总控制 *****************
hazard hazard(
    regwriteE,regwriteM,regwriteW,memtoRegE,memtoRegM,branchD,
    rsD,rtD,rsE,rtE,reg_waddrM,reg_waddrW,reg_waddrE,
    stallF,stallD,flushE,forwardAD,forwardBD,
    forwardAE, forwardBE
);

endmodule