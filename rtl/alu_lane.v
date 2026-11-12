// alu_lane.v
// Single 8-bit ALU lane used by each SIMD lane. Purely combinational.
//
//  opcode | operation
//  -------+------------------------------------------
//   000   | ADD  a + b   (wraps to 8 bits)
//   001   | SUB  a - b   (wraps to 8 bits)
//   010   | AND  a & b
//   011   | OR   a | b
//   100   | LTU  1 if a < b (unsigned), else 0
//   other | 0

`timescale 1ns/1ps

module alu_lane (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] opcode,
    output reg  [7:0] result
);

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_LTU = 3'b100;

    // every path assigns result, so no latch is inferred
    always @(*) begin
        case (opcode)
            OP_ADD:  result = a + b;
            OP_SUB:  result = a - b;
            OP_AND:  result = a & b;
            OP_OR:   result = a | b;
            OP_LTU:  result = (a < b) ? 8'd1 : 8'd0;
            default: result = 8'd0;
        endcase
    end

endmodule
