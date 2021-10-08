`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/02 17:28:41
// Design Name: 
// Module Name: mips
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


module mips(
    input wire clka, rst,
    output wire inst_ram_ena, data_ram_ena,
    output wire  data_ram_wea,
    output wire [31:0] pc, alu_result, mem_wdata, 
    input wire [31:0] instr, mem_rdata
    );
    
wire memtoregE,memtoregM, memtoregW, regwriteE;
wire actual_takeM, pred_takeM;
wire [31:0] instrD;
wire pcsrc, zero;
wire [2:0] alucontrol;
assign inst_ram_ena = 1'b1;

floprc #(32) sigs_D(
    .clk(clka), 
    .rst(rst), 
    .en(~stallD),
    .clear(pcsrcD),
    .d(instr),
    .q(instrD)
    );
wire branch;
wire stallD, pcsrcD;
controller c(clka, instrD[31:26],instrD[5:0],zero,actual_takeM,pred_takeM,memtoregE,memtoregM,memtoregW,
    data_ram_wea,pcsrc,alusrc,regdst,regwriteE,regwriteM, regwriteW,jump,data_ram_ena, alucontrol, branch);
    
datapath datapath(
    .clka(clka),
    .rst(rst),
    .branch(branch),
    .memtoregM(memtoregM),
    .pcsrc(pcsrc),
    .instr(instr),
    .mem_rdata(mem_rdata),
    .pc(pc), 
    .alu_resultM(alu_result), 
    .writedataM(mem_wdata),
    .zeroM(zero),
    .stallD(stallD), 
    .pcsrcD(pcsrcD),
    .jump(jump), 
    .alusrc(alusrc), 
    .memtoregE(memtoregE),
    .memtoregW(memtoregW),
    .regwriteE(regwriteE),
    .regwriteM(regwriteM), 
    .regwriteW(regwriteW), 
    .regdst(regdst),
    .alucontrol(alucontrol),
    .actual_takeM(actual_takeM),
    .pred_takeM(pred_takeM)
    );
    

endmodule
