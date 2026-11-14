`timescale 1ns/1ps

// One ALU reused for four byte elements; matching SIMD host interface.
// E0 captures, E1..E4 execute, E5 writes and pulses done.
module scalar_top (
    input wire clk, reset, start,
    input wire [2:0] opcode,
    input wire [1:0] src_a, src_b, dst,
    input wire host_write_enable,
    input wire [1:0] host_write_addr,
    input wire [31:0] host_write_data,
    input wire [1:0] host_read_addr,
    output wire [31:0] host_read_data,
    output wire busy,
    output reg done
);
    localparam [1:0] IDLE=0, EXECUTE=1, WRITEBACK=2;
    reg [1:0] state, element_index, saved_dst;
    reg [2:0] saved_opcode;
    reg [31:0] operand_a, operand_b, collected_result;
    wire [31:0] read_a, read_b;
    wire [7:0] element_result;
    wire accept = start && !busy && !reset;
    wire host_write = host_write_enable && !busy && !start && !reset;
    wire writeback = state == WRITEBACK;
    assign busy = state != IDLE;
    assign host_read_data = read_a;
    vector_regfile storage (
        .clk(clk), .reset(reset),
        .read_addr_a(accept ? src_a : host_read_addr),
        .read_addr_b(src_b), .read_data_a(read_a), .read_data_b(read_b),
        .write_enable(writeback || host_write),
        .write_addr(writeback ? saved_dst : host_write_addr),
        .write_data(writeback ? collected_result : host_write_data)
    );
    alu_lane scalar_alu (
        .a(operand_a[element_index*8 +: 8]),
        .b(operand_b[element_index*8 +: 8]),
        .opcode(saved_opcode), .result(element_result)
    );
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE; element_index <= 0; saved_dst <= 0;
            saved_opcode <= 0; operand_a <= 0; operand_b <= 0;
            collected_result <= 0; done <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE: if (accept) begin
                    operand_a <= read_a; operand_b <= read_b;
                    saved_opcode <= opcode; saved_dst <= dst;
                    element_index <= 0; collected_result <= 0;
                    state <= EXECUTE;
                end
                EXECUTE: begin
                    collected_result[element_index*8 +: 8] <= element_result;
                    if (element_index == 3) state <= WRITEBACK;
                    else element_index <= element_index + 1'b1;
                end
                WRITEBACK: begin state <= IDLE; done <= 1; end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
