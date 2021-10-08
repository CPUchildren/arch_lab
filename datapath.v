`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/02 09:09:32
// Design Name: 
// Module Name: datapath
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module datapath(
    input wire clka,rst, branch, memtoregM,
    input wire [31:0] instr, mem_rdata,
    output wire zeroM, stallD, pcsrcD,
    output wire [31:0] pc, alu_resultM, writedataM,
    
    input wire jump, pcsrc, alusrc, memtoregE, memtoregW, regwriteE, regwriteM, regwriteW, regdst,
    input wire [2:0] alucontrol,
    
    output wire actual_takeM, pred_takeM
    );

wire [31:0] pc_plus4, rd1D, rd2D, imm_extend, pc_next, pc_next_jump, instr_sl2, pc_next_M1, pc_next_M2;
wire [31:0] mem_rdata, alu_srcB, wd3, imm_sl2, pc_branch, pc_branchE, pc_branchM, pcD, pcE, pcM;
wire [4:0] write2regE, write2regM, write2regW;
wire [31:0] rd1, rd2, writedataE;
wire stallF, stallE, flushE;

wire [31:0] instrD, pc_plus4D, pc_plus4E, pc_plus4M, rd1E, rd2E, imm_extendE, alu_result, alu_resultW, mem_rdataW;
wire [4:0] rsD, rtD, rdD, rsE, rtE, rdE, rtM, rdM, rtW, rdW;
wire zero;
wire equalD, pred_takeD,pred_takeE,pred_takeM;
wire branchD, branchE, branchM;
wire actual_takeE, actual_takeM;
wire [31:0] eql1, eql2;

wire [1:0] forwardAE, forwardBE;
wire forwardAD, forwardBD;

wire overflow;

mux2 #(32) eql_1( .a(alu_resultM), .b(rd1D), .s(forwardAD), .y(eql1) );

mux2 #(32) eql_2( .a(alu_resultM), .b(rd2D), .s(forwardBD), .y(eql2) );

eqcmp pc_predict( .a(eql1), .b(eql2), .op(instrD[31:26]), .rt(rtD), .y(equalD) );


//==================================F==========================================//
    //mux2 for pc_next_M1
mux2 #(32) mux_pc_M1( .a(pc_plus4M), .b(pc_plus4), .s(~(actual_takeM==pred_takeM)&pred_takeM), .y(pc_next_M1) );
    
    //mux2 for pc_next_M2
mux2 #(32) mux_pc_M2( .a(pc_branchM), .b(pc_next_M1), .s(~(actual_takeM==pred_takeM)&actual_takeM), .y(pc_next_M2) );

    //mux2 for pc_next
mux2 #(32) mux_pc( .a(pc_branch), .b(pc_next_M2), .s(pred_takeD), .y(pc_next) );
    
    //left shift 2 for pc_jump instr_index
sl2 sl2_instr( .a(instrD), .y(instr_sl2) );
    
    //mux for pc_jump
mux2 #(32) mux_pc_jump( .a({pc_plus4[31:28],instr_sl2[27:0]}), .b(pc_next), .s(jump), .y(pc_next_jump) );

    //pc
pc pc1( .clk(clka), .rst(rst), .en(~stallF), .din(pc_next_jump), .q(pc) );

    //pc + 4
adder pc_plus_4( .a(pc), .b(32'd4), .y(pc_plus4) );
//==================================F==========================================//
    
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>F_D<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //
floprc #(32) r1D( .clk(clka), .rst(rst), .en(~stallD), .clear(~(actual_takeM==pred_takeM)|jump), .d(instr), .q(instrD) );
    
floprc #(32) pc_D( .clk(clka), .rst(rst), .en(~stallD), .clear(~(actual_takeM==pred_takeM)|jump), .d(pc), .q(pcD) );
    
floprc #(32) r2D( .clk(clka), .rst(rst), .en(~stallD), .clear(~(actual_takeM==pred_takeM)|jump), .d(pc_plus4), .q(pc_plus4D) );
    
assign branchD = branch;
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>F_D<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //



//==================================D==========================================//
    //imm extend
sign_extend sign_extend1( .a(instrD[15:0]), .y(imm_extend) );

    //left shift 2 for pc_brranch imm
sl2 sl2_imm( .a(imm_extend), .y(imm_sl2) );
    
    //pc_branch = pc + 4 + (sign_ext imm << 2)
adder pc_branch1( .a(pc_plus4D), .b(imm_sl2), .y(pc_branch) );
    


assign rtD = instrD[20:16];
assign rdD = instrD[15:11];
assign rsD = instrD[25:21];
assign pcsrcD = equalD&branch;

    //regfile
regfile regfile( .clk(clka), .we3(regwriteW), .ra1(instrD[25:21]), .ra2(instrD[20:16]), .wa3(write2regW[4:0]), .wd3(wd3), .rd1(rd1D), .rd2(rd2D) );
//==================================D==========================================//
  
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>D_E<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //
floprc #(32) r3E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(rd1D), .q(rd1E) );
    
floprc #(32) pc_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pcD), .q(pcE) );
    
floprc #(1) branch_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(branchD), .q(branchE) );
    
floprc #(1) pred_take_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pred_takeD), .q(pred_takeE) );

floprc #(1) pred_global_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pred_globalD), .q(pred_globalE) );

floprc #(1) pred_local_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pred_localD), .q(pred_localE) );
    
floprc #(1) actual_take_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pcsrcD), .q(actual_takeE) );

floprc #(32) r4E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(rd2D), .q(rd2E) );

floprc #(5) r6E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(rtD), .q(rtE) );

floprc #(5) r7E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(rdD), .q(rdE) );

floprc #(32) r8E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pc_plus4D), .q(pc_plus4E) );
    
floprc #(32) r9E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(imm_extend), .q(imm_extendE) );

floprc #(5) rs_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(rsD), .q(rsE) );
    
floprc #(32) pc_plus4_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pc_plus4D), .q(pc_plus4E) );
    
floprc #(32) pc_branch_E( .clk(clka), .rst(rst), .en(1'b1), .clear(flushE|~(actual_takeM==pred_takeM)), .d(pc_branch), .q(pc_branchE) );
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>D_E<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //


//==================================E==========================================//   
    //mux2 for wd3, write addr port of regfile
mux2 #(5) mux_wa3( .a(rdE), .b(rtE), .s(regdst), .y(write2regE) );
    

    
mux3 #(32) srcA_sel(rd1E, wd3, alu_resultM, forwardAE, rd1);
mux3 #(32) srcB_sel(rd2E, wd3, alu_resultM, forwardBE, rd2);

assign writedataE = rd2;

    //mux2 for alu_srcB
mux2 #(32) mux_alu_srcb( .a(imm_extendE), .b(rd2), .s(alusrc), .y(alu_srcB) );
    
    //alu
alu_always alu( .clk(clka), .a(rd1), .b(alu_srcB), .f(alucontrol[2:0]), .y(alu_result), .overflow(overflow), .zero(zero) );
//==================================E==========================================//

    
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>E_M<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //
floprc #(32) writedata_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(writedataE), .q(writedataM) ); 
    
floprc #(32) pc_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(pcE), .q(pcM) );
    
floprc #(1) branch_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(branchE), .q(branchM) ); 
    
floprc #(1) pred_take_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(pred_takeE), .q(pred_takeM) ); 

floprc #(1) pred_global_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(pred_globalE), .q(pred_globalM) );

floprc #(1) pred_local_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(pred_localE), .q(pred_localM) );
    
floprc #(1) actual_take_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(actual_takeE), .q(actual_takeM) );    

floprc #(32) r10M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(alu_result), .q(alu_resultM) );
    
floprc #(1) r11M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(zero), .q(zeroM) );
    
floprc #(32) r12M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(write2regE), .q(write2regM) );
    
floprc #(32) r13M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(pc_branchE), .q(pc_branchM) );

floprc #(5) r7M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(rdE), .q(rdM) );
    
floprc #(32) pc_plus4_M( .clk(clka), .rst(rst), .en(1'b1), .clear(flushM1), .d(pc_plus4E), .q(pc_plus4M) );
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>E_M<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //


    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>M_W<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //
//mem_rdata    
floprc #(32) r13W( .clk(clka), .rst(rst), .en(1'b1), .clear(1'b0), .d(alu_resultM), .q(alu_resultW) );
    
floprc #(32) r14W( .clk(clka), .rst(rst), .en(1'b1), .clear(1'b0), .d(mem_rdata), .q(mem_rdataW) );
    
floprc #(5) r6W( .clk(clka), .rst(rst), .en(1'b1), .clear(1'b0), .d(write2regM), .q(write2regW) );
    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>M_W<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< //

//==================================W==========================================//    
    //mux2 for wd3, write data port of regfile
mux2 #(32) mux_wd3( .a(mem_rdataW), .b(alu_resultW), .s(memtoregW), .y(wd3) );
//==================================W==========================================//
    



//==================================hazard==========================================//
hazard hazard( .rsD(rsD), .rtD(rtD), .rsE(rsE), .rtE(rtE), .writeregE(write2regE), .writeregM(write2regM), .writeregW(write2regW), .regwriteE(regwriteE), .regwriteM(regwriteM), .regwriteW(regwriteW), .memtoregE(memtoregE), .memtoregM(memtoregM), .branchD(branch), .forwardAE(forwardAE), .forwardBE(forwardBE), .forwardAD(forwardAD), .forwardBD(forwardBD), .stallF(stallF), .stallD(stallD), .flushE(flushE) );
//==================================hazard==========================================//

//============================branch_predict=======================================//
wire flushD,flushE1, flushM1;
wire pred_globalD, pred_localD, pred_globalE, pred_localE, pred_globalM, pred_localM;
wire [13:0] CPHT_indexD, CPHT_indexM;
assign flushD = actual_takeM|jump;
assign flushE1 = flushE|~(actual_takeM==pred_takeM);
assign flushM1 = ~(actual_takeM==pred_takeM);
branch_predict branch_predict( .clk(clka), .rst(rst), .flushD(actual_takeM|jump), .stallD(stallD), .pcF(pc), .pcM(pcM), .branchM(branchM), .actual_takeM(actual_takeM), .branchD(branch), .pred_takeD(pred_localD) );
branch_predict_global branch_predict_global( .clk(clka), .rst(rst), .flushD(actual_takeM|jump),.flushE(flushE1), .flushM(flushM1), .stallD(stallD), .pcF(pc), .pcM(pcM), .branchM(branchM), .actual_takeM(actual_takeM), .pred_takeM(pred_takeM), .branchD(branch), .pred_takeD(pred_globalD), .PHT_index(CPHT_indexD), .update_PHT_index(CPHT_indexM) );
branch_predict_complete branch_predict_complete(
    clka, rst,

    pred_globalD, pred_localD,
    pred_globalM, pred_localM,

    CPHT_indexD, CPHT_indexM,

    actual_takeM,

    pred_takeD 
    );
//============================branch_predict=======================================//
    

endmodule
