// tb_alu_lane.v
// Self-checking testbench for alu_lane.
//
// Part 1: directed cases with hand-computed expected values
//         (wraparound, unsigned compare, unused opcodes).
// Part 2: exhaustive sweep of all opcodes and all 8-bit a/b values
//         against a reference model.
//
// Run with Icarus Verilog:
//   iverilog -g2005 -Wall -o tb_alu_lane.vvp rtl/alu_lane.v tb/tb_alu_lane.v
//   vvp tb_alu_lane.vvp
// Waveform for the directed part is written to tb_alu_lane.vcd.

`timescale 1ns/1ps

module tb_alu_lane;

    reg  [7:0] a;
    reg  [7:0] b;
    reg  [2:0] opcode;
    wire [7:0] result;

    integer checks;
    integer errors;
    integer i, j, k;

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_LTU = 3'b100;

    alu_lane dut (
        .a      (a),
        .b      (b),
        .opcode (opcode),
        .result (result)
    );

    // reference model for the exhaustive sweep
    function [7:0] ref_alu;
        input [7:0] x;
        input [7:0] y;
        input [2:0] op;
        begin
            case (op)
                OP_ADD:  ref_alu = x + y;
                OP_SUB:  ref_alu = x - y;
                OP_AND:  ref_alu = x & y;
                OP_OR:   ref_alu = x | y;
                OP_LTU:  ref_alu = (x < y) ? 8'd1 : 8'd0;
                default: ref_alu = 8'd0;
            endcase
        end
    endfunction

    task check;
        input [7:0] ta;
        input [7:0] tb_val;
        input [2:0] op;
        input [7:0] expected;
        begin
            a      = ta;
            b      = tb_val;
            opcode = op;
            #1;
            checks = checks + 1;
            // !== so that X/Z on the output also counts as a failure
            if (result !== expected) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL: op=%b a=%0d b=%0d -> result=%0d expected=%0d",
                             op, ta, tb_val, result, expected);
            end
        end
    endtask

    initial begin
        checks = 0;
        errors = 0;
        a      = 8'd0;
        b      = 8'd0;
        opcode = 3'd0;

        $dumpfile("tb_alu_lane.vcd");
        $dumpvars(0, tb_alu_lane);

        // ---------------- directed tests ----------------
        $display("Directed tests");

        // ADD
        check(8'd3,   8'd4,   OP_ADD, 8'd7);
        check(8'd0,   8'd0,   OP_ADD, 8'd0);
        check(8'd200, 8'd100, OP_ADD, 8'd44);    // 300 wraps to 44
        check(8'd255, 8'd1,   OP_ADD, 8'd0);     // carry out dropped
        check(8'd128, 8'd128, OP_ADD, 8'd0);
        check(8'd255, 8'd255, OP_ADD, 8'd254);

        // SUB
        check(8'd10,  8'd3,   OP_SUB, 8'd7);
        check(8'd100, 8'd100, OP_SUB, 8'd0);
        check(8'd3,   8'd10,  OP_SUB, 8'd249);   // -7 wraps to 249
        check(8'd0,   8'd1,   OP_SUB, 8'd255);
        check(8'd0,   8'd255, OP_SUB, 8'd1);

        // AND
        check(8'hF0,  8'h3C,  OP_AND, 8'h30);
        check(8'hFF,  8'h00,  OP_AND, 8'h00);
        check(8'hAA,  8'hFF,  OP_AND, 8'hAA);
        check(8'hAA,  8'h55,  OP_AND, 8'h00);

        // OR
        check(8'hF0,  8'h0F,  OP_OR,  8'hFF);
        check(8'hA0,  8'h05,  OP_OR,  8'hA5);
        check(8'h00,  8'h00,  OP_OR,  8'h00);
        check(8'hAA,  8'h55,  OP_OR,  8'hFF);

        // unsigned less-than
        check(8'd3,   8'd5,   OP_LTU, 8'd1);
        check(8'd5,   8'd3,   OP_LTU, 8'd0);
        check(8'd7,   8'd7,   OP_LTU, 8'd0);     // equal -> 0
        check(8'd0,   8'd255, OP_LTU, 8'd1);
        check(8'd255, 8'd0,   OP_LTU, 8'd0);
        check(8'd127, 8'd128, OP_LTU, 8'd1);     // signed compare would give 0
        check(8'd200, 8'd100, OP_LTU, 8'd0);     // signed compare would give 1

        // unused opcodes must give zero
        check(8'hFF,  8'hFF,  3'b101, 8'd0);
        check(8'h12,  8'h34,  3'b110, 8'd0);
        check(8'h80,  8'h01,  3'b111, 8'd0);

        $display("  %0d directed checks, %0d errors", checks, errors);

        // keep the VCD small: only the directed part is dumped
        $dumpoff;

        // ---------------- exhaustive sweep ----------------
        $display("Exhaustive sweep (8 opcodes x 256 x 256)");
        for (k = 0; k < 8; k = k + 1)
            for (i = 0; i < 256; i = i + 1)
                for (j = 0; j < 256; j = j + 1)
                    check(i[7:0], j[7:0], k[2:0], ref_alu(i[7:0], j[7:0], k[2:0]));

        $display("");
        if (errors == 0)
            $display("PASS: %0d checks, 0 errors", checks);
        else
            $display("FAIL: %0d checks, %0d errors", checks, errors);

        $finish;
    end

endmodule
