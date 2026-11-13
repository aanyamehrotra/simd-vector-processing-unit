`timescale 1ns/1ps

module vector_regfile (
    input  wire        clk,
    input  wire        reset,
    input  wire [1:0]  read_addr_a,
    input  wire [1:0]  read_addr_b,
    output wire [31:0] read_data_a,
    output wire [31:0] read_data_b,
    input  wire        write_enable,
    input  wire [1:0]  write_addr,
    input  wire [31:0] write_data
);
    reg [31:0] registers [0:3];
    integer index;

    // Read ports reflect the addressed registers continuously. A read of
    // the write address sees the new value after the rising edge.
    assign read_data_a = registers[read_addr_a];
    assign read_data_b = registers[read_addr_b];

    always @(posedge clk) begin
        if (reset) begin
            for (index = 0; index < 4; index = index + 1)
                registers[index] <= 32'b0;
        end else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end
endmodule
