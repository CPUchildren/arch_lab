`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/20 20:47:50
// Design Name: 
// Module Name: controller
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


module controller(
    input wire clka,
	input wire[5:0] op,funct,
	input wire zero,
	input wire actual_takeM,
    input wire pred_takeM,
	output wire memtoregE, memtoregM, memtoregW,memwrite,
	output wire pcsrc,alusrc,
	output wire regdst,regwriteE,regwriteM, regwriteW,
	output wire jump, memen,
	output wire[2:0] alucontrolE,
	output wire branch
    );
    wire [7:0] sigs;
	wire[1:0] aluop;
//	wire branch;

	main_decoder md( op,sigs, aluop);
	alu_dec ad(funct,aluop,alucontrolD);
	
//	assign branch = sigs[3];
	assign jump = sigs[6];
	
	//regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump, memen
	wire [2:0] alucontrolD;
	floprc #(3) alucontrol_E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1),
    .clear(1'b0),
    .d(alucontrolD),
    .q(alucontrolE)
    );
    
    assign branch = sigs[3];
    
    wire [7:0] sigsE;
	
	floprc #(8) sigs_E(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1),
    .clear(~(actual_takeM==pred_takeM)),
    .d(sigs),
    .q(sigsE)
    );
    
    assign alusrc = sigsE[2];
    assign regdst = sigsE[1];
    assign memtoregE = sigsE[5];
    assign regwriteE = sigsE[0];
    
    //regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump, memen
    wire [7:0] sigsM;
    floprc #(8) sigs_M(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1),
    .clear(~(actual_takeM==pred_takeM)),
    .d(sigsE),
    .q(sigsM)
    );
    
//    assign branch = sigsM[3];
    assign memwrite = sigsM[4];
    assign memen = sigsM[7];
    assign regwriteM = sigsM[0];
    assign memtoregM = sigsM[5];
    
    //regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump, memen
    wire [7:0] sigsW;
    floprc #(8) sigs_W(
    .clk(clka), 
    .rst(rst), 
    .en(1'b1),
    .clear(1'b0),
    .d(sigsM),
    .q(sigsW)
    );
    
    assign regwriteW = sigsW[0];
    assign memtoregW = sigsW[5];
//    assign regdst = sigsW[1];
    

	assign pcsrc = branch & zero;

endmodule
