`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/19 11:51:33
// Design Name: 
// Module Name: maindec
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

`include "instrdefines.vh"
module maindec(
    input wire clk,rst,flushE,
    input wire [31:0]instrD,
    output wire regwriteW,regdstE,alusrcAE,alusrcBE,branchD,memWriteM,memtoRegW,jumpD,
    output wire regwriteE,regwriteM,memtoRegE,memtoRegM
);
    // Decoder
    wire [5:0]op;
    wire [5:0]funct;
    wire [4:0]rt;
    wire [10:0] signsE,signsW,signsM;
    reg [10:0] signsD;
    wire ena;
    assign op = instrD[31:26];
    assign funct = instrD[5:0];
    assign rt = instrD[20:16];
    assign regwriteW = signsW[6];
    assign regwriteE = signsE[6];
    assign regwriteM = signsM[6];
    assign regdstE = signsE[5];
    assign alusrcAE = signsE[7];
    assign alusrcBE = signsE[4];
    assign branchD = signsD[3];
    assign memWriteM = signsM[2];
    assign memtoRegW = signsW[1];
    assign memtoRegE = signsE[1];
    assign memtoRegM = signsM[1];
    assign jumpD = signsD[0];

    // signsD = {10bal,9jr,8jal,7alusrcA,6regwrite,5regdst,,4alusrcB,3branch,2memWrite,1memtoReg,0jump}
    // XXX 分支跳转指令增加了bal,jr,jal信号(可以统一之后�?000)
    always @(*) begin
        case(op)
            `OP_R_TYPE:
                case (funct)
                    //移位指令
                    `FUN_SLL   : signsD <= 11'b00011110000;
                    `FUN_SLLV  : signsD <= 11'b00001110000;
                    `FUN_SRL   : signsD <= 11'b00011110000;
                    `FUN_SRLV  : signsD <= 11'b00001110000;
                    `FUN_SRA   : signsD <= 11'b00011110000;
                    `FUN_SRAV  : signsD <= 11'b00001110000;
                    //逻辑和算术指�?
                    `FUN_AND   : signsD <= 11'b00001100000;    //and
                    `FUN_OR    : signsD <= 11'b00001100000;    //or
                    `FUN_XOR   : signsD <= 11'b00001100000;   //xor
                    `FUN_NOR   : signsD <= 11'b00001100000;   //nor
                    `FUN_SLT   : signsD <= 11'b00001100000;   //slt
                    `FUN_SLTU  : signsD <= 11'b00001100000;   //sltu
                    `FUN_ADD   : signsD <= 11'b00001100000;   //add
                    `FUN_ADDU  : signsD <= 11'b00001100000;   //addu
                    `FUN_SUB   : signsD <= 11'b00001100000;   //sub
                    `FUN_SUBU  : signsD <= 11'b00001100000;   //subu
                    `FUN_MULT  : signsD <= 11'b00001100000;   //mult
                    `FUN_MULTU : signsD <= 11'b00001100000;  //multu
                    `FUN_DIV   : signsD <= 11'b00001100000;   //div
                    `FUN_DIVU  : signsD <= 11'b00001100000;   //divu
                    // 分支跳转
                    `FUN_JR    : signsD <= 11'b01000000001;
                    `FUN_JALR  : signsD <= 11'b000011;
                    default: signsD <=11'b00000000000;
                endcase
            // 访存指令
            `OP_LB    : signsD <= 11'b00001010010;
            `OP_LBU   : signsD <= 11'b00001010010;
            `OP_LH    : signsD <= 11'b00001010010;
            `OP_LHU   : signsD <= 11'b00001010010;
            `OP_LW    : signsD <= 11'b00001010010; // lw
            `OP_SB    : signsD <= 11'b00000010110;
            `OP_SH    : signsD <= 11'b00000010110;
            `OP_SW    : signsD <= 11'b00000010110; // sw
            //arithmetic type
            `OP_ADDI  : signsD <= 11'b00001010000; // addi
            `OP_ADDIU : signsD <= 11'b00001010000; // addiu     //alusrcA应该�?1
            `OP_SLTI  : signsD <= 11'b00001010000;// slti
            `OP_SLTIU : signsD <= 11'b00001010000; // sltiu
            //logical type
            `OP_ANDI  : signsD <= 11'b00001010000; // andi
            `OP_ORI   : signsD <= 11'b00001010000; // ori
            `OP_XORI  : signsD <= 11'b00001010000; // xori
            `OP_LUI   : signsD <= 11'b00001010000; // lui
            
            // 分支跳转指令
            // alusrcA,regwrite,regdst,alusrcB,branch,memWrite,memtoReg,jump
//            `OP_BEQ   : signsD <= 8'b00001000; // BEQ
//            `OP_BNE   : signsD <= 8'b00001000; // BNE
//            // `OP_BGEZ  : signsD <= 8'b00001000; // BGEZ
//            `OP_BGTZ  : signsD <= 8'b00001000; // BGTZ
//            `OP_BLEZ  : signsD <= 8'bb00001000; // BLEZ  
//            // `OP_BLTZ  : signsD <= 8'b00001000; // BLTZ  
//            `OP_BGEZAL: signsD <= 8'b01001000; // BGEZAL
//            `OP_BLTZAL: signsD <= 8'b01001000; // BLTZAL
//            `OP_J     : signsD <= 11'b00000000001; // J     
//            `OP_JAL   : signsD <= 11'b00101000000; // XXX JUMP信号（为啥不�?1�?
//            `OP_JR    : signsD <= 11'b01000000001; // JR
//            `OP_JALR  : signsD <= 11'b01001100000; // JALR  // XXX JUMP信号（为啥不�?1�?
            // 数据移动指令
            default:signsD <=11'b00000000000;
        endcase
    end
   //<=====CHANGED======>
    // Execute
    flopr #(11) dff1E(clk,rst,signsD,signsE);
    // Mem
    flopr #(11) dff1M(clk,rst,signsE,signsM);
    // Write
    flopr #(11) dff1W(clk,rst,signsM,signsW);    
    
endmodule
//module maindec(
//    input wire [5:0] op,
//     output wire regwrite,regdst,alusrc,memwrite,memtoreg,jump,branch,
//     output wire [1:0] aluop
////    output reg [9:0] sigs
////     output wire memen //data_ram
//    );
//    wire [8:0] sigs;
//    assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop}=sigs;
//    assign sigs=(op==6'b000000)? 9'b110000010: //R-type
//                 (op==6'b100011)? 9'b101001000: //lw
//                 (op==6'b101011)? 9'b001010000://sw
//                 (op==6'b000100)? 9'b000100001: //beq
//                 (op==6'b001000)? 9'b101000000: //addi
//                 (op==6'b000010)? 9'b000000100: 9'b00000000;//jump
////    wire [9:0] sigs;
////    assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop,memen}=sigs;
////    assign sigs=(op==6'b000000)? 10'b1100000100: //R-type
////                 (op==6'b100011)? 10'b1010010001: //lw
////                 (op==6'b101011)? 10'b0010100001://sw
////                 (op==6'b000100)? 10'b0001000010: //beq
////                 (op==6'b001000)? 10'b1010000000: //addi
////                 (op==6'b000010)? 10'b0000001000: 10'b000000000;//jump
//endmodule

