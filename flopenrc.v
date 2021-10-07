`timescale 1ns/1ps
// ���� enable��reset �� clear �Ĵ�����
module flopenrc #(parameter WIDTH = 32) (
    input wire clk,rst,clear,ena,
    input wire[WIDTH-1:0]d,
    output reg[WIDTH-1:0]q
);
    always @(posedge clk) begin
        if(rst) q<=0;
        else if (clear) q<=0;
        else if (ena) q<=d;
    end
    
endmodule