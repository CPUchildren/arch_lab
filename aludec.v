`include "instrdefines.vh"
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/19 11:01:17
// Design Name: 
// Module Name: aludec
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


module aludec(
//    input wire [5:0] funct,
//    input wire [1:0] op,
//    output reg [2:0] alucontrol
    input clk,
    input rst,
    input wire flushE,
//    input ena,
    input wire [31:0]instrD,
    output wire[7:0]aluopE
    );
    wire[5:0]op;
    wire[5:0]funct;
    wire[4:0]rt;
    reg[7:0]aluopD;
    
    assign op = instrD[31:26];
    assign funct = instrD[5:0];
    assign rt = instrD[20:16];
    
    always @(*) begin
        case (op)
            `OP_R_TYPE:
                case (funct)
                    //逻辑指令
                    `FUN_AND   : aluopD <= `ALUOP_AND   ;
                    `FUN_OR    : aluopD <= `ALUOP_OR    ;
                    `FUN_XOR   : aluopD <= `ALUOP_XOR   ;
                    `FUN_NOR   : aluopD <= `ALUOP_NOR   ;
                    //算术运算指令
                    `FUN_SLT   : aluopD <= `ALUOP_SLT   ;
                    `FUN_SLTU  : aluopD <= `ALUOP_SLTU  ;
                    `FUN_ADD   : aluopD <= `ALUOP_ADD   ;
                    `FUN_ADDU  : aluopD <= `ALUOP_ADDU  ;
                    `FUN_SUB   : aluopD <= `ALUOP_SUB   ;
                    `FUN_SUBU  : aluopD <= `ALUOP_SUBU  ;
                    //移位指令
                    `FUN_SLL   : aluopD <= `ALUOP_SLL   ;
                    `FUN_SLLV  : aluopD <= `ALUOP_SLLV  ;
                    `FUN_SRL   : aluopD <= `ALUOP_SRL   ;
                    `FUN_SRLV  : aluopD <= `ALUOP_SRLV  ;
                    `FUN_SRA   : aluopD <= `ALUOP_SRA   ;
                    `FUN_SRAV  : aluopD <= `ALUOP_SRAV  ;
                    default:aluopD <=  8'b00000000;
                endcase
            //逻辑指令
            `OP_ANDI: aluopD <= `ALUOP_ANDI;
            `OP_XORI: aluopD <= `ALUOP_XORI;
            `OP_LUI : aluopD <= `ALUOP_LUI;
            `OP_ORI : aluopD <= `ALUOP_ORI;
            //算术指令
            `OP_ADDI: aluopD <= `ALUOP_ADDI;
            `OP_ADDIU: aluopD <= `ALUOP_ADDIU;
            `OP_SLTI: aluopD <= `ALUOP_SLTI;
            `OP_SLTIU: aluopD <= `ALUOP_SLTIU;
//            // 访存指令
//            `OP_LB:   aluopD <= `ALUOP_ADD;
//            `OP_LBU:  aluopD <= `ALUOP_ADD;
//            `OP_LH:   aluopD <= `ALUOP_ADD;
//            `OP_LHU:  aluopD <= `ALUOP_ADD;
//            `OP_LW:   aluopD <= `ALUOP_ADD;
//            `OP_SB:   aluopD <= `ALUOP_ADD;
//            `OP_SH:   aluopD <= `ALUOP_ADD;
//            `OP_SW:   aluopD <= `ALUOP_ADD;
//            // 分支跳转指令，D阶段判断，不�?要经过alu
            default: aluopD <=8'b00000000;
        endcase
    end
    // 
    floprc #(8) dff2E(clk,rst,flushE,aluopD,aluopE);
    
    
    
//    always @(*) begin
//        case(op)             
//            2'b00: alucontrol<=3'b010; //add for lw/sw 
//            2'b01: alucontrol<=3'b110;  //sub for beq 
//            default:
//                case(funct)
//                    6'b100000: alucontrol<=3'b010;  
//                    6'b100010: alucontrol<=3'b110;  
//                    6'b100100: alucontrol<=3'b000;
//                    6'b100101: alucontrol<=3'b001;
//                    6'b101010: alucontrol<=3'b111;
//                    default: alucontrol<=3'b100;
//                endcase
//        endcase
//    end
endmodule

