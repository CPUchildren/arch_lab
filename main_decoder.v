`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/20 20:17:14
// Design Name: 
// Module Name: main_decoder
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


module main_decoder(
	input wire[5:0] op,
	
    output wire [7:0] sigs,

	output wire[1:0] aluop
    );
	reg[9:0] controls;
//	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop, memen} = controls;
assign {sigs[0],sigs[1],sigs[2],sigs[3],sigs[4],sigs[5],sigs[6],aluop, sigs[7]} = controls;
	always @(*) begin
		case (op)
			6'b000000:controls <= 10'b1100000100;//R-TYRE
			6'b100011:controls <= 10'b1010010000;//LW
			6'b101011:controls <= 10'b0010100001;//SW
			6'b000100:controls <= 10'b0001000010;//BEQ
			6'b001000:controls <= 10'b1010000000;//ADDI
			6'b000010:controls <= 10'b0000001000;//J
			default:  controls <= 10'b0000000000;//illegal op
		endcase
	end

endmodule

