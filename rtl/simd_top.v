`timescale 1ns/1ps

// Four 8-bit lanes in each 32-bit vector; lane 0 is bits [7:0].
// Host writes are accepted only while idle and when start is low.
// A start accepted while idle captures operands, opcode and destination.
// Completion occurs two rising edges after acceptance. Reset cancels work.
module simd_top (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [2:0] opcode,
    input wire [1:0] src_a, src_b, dst,
    input wire host_write_enable,
    input wire [1:0] host_write_addr,
    input wire [31:0] host_write_data,
    input wire [1:0] host_read_addr,
    output wire [31:0] host_read_data,
    output wire busy,
    output wire done
);
    wire writeback;
    wire accept = start && !busy && !reset;
    wire host_write = host_write_enable && !busy && !start && !reset;
    wire [31:0] read_a, read_b, vector_result;
    reg [31:0] operand_a, operand_b;
    reg [2:0] saved_opcode;
    reg [1:0] saved_dst;

    vector_control control (
        .clk(clk), .reset(reset), .start(start),
        .busy(busy), .write_enable(writeback), .done(done)
    );

    // Idle read port A doubles as the host inspection port.
    vector_regfile storage (
        .clk(clk), .reset(reset),
        .read_addr_a(accept ? src_a : host_read_addr),
        .read_addr_b(src_b), .read_data_a(read_a), .read_data_b(read_b),
        .write_enable(writeback || host_write),
        .write_addr(writeback ? saved_dst : host_write_addr),
        .write_data(writeback ? vector_result : host_write_data)
    );
    assign host_read_data = read_a;

    always @(posedge clk) begin
        if (reset) begin
            operand_a <= 32'd0;
            operand_b <= 32'd0;
            saved_opcode <= 3'd0;
            saved_dst <= 2'd0;
        end else if (accept) begin
            operand_a <= read_a;
            operand_b <= read_b;
            saved_opcode <= opcode;
            saved_dst <= dst;
        end
    end

    genvar lane;
    generate
        for (lane = 0; lane < 4; lane = lane + 1) begin : lanes
            alu_lane alu (
                .a(operand_a[lane*8 +: 8]),
                .b(operand_b[lane*8 +: 8]),
                .opcode(saved_opcode),
                .result(vector_result[lane*8 +: 8])
            );
        end
    endgenerate
endmodule
