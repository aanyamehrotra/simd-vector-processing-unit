`timescale 1ns/1ps

module tb_vector_regfile;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg reset = 1'b1;
    reg [1:0] read_addr_a = 2'd0;
    reg [1:0] read_addr_b = 2'd1;
    wire [31:0] read_data_a;
    wire [31:0] read_data_b;
    reg write_enable = 1'b0;
    reg [1:0] write_addr = 2'd0;
    reg [31:0] write_data = 32'd0;

    vector_regfile dut (
        .clk(clk),
        .reset(reset),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .read_data_a(read_data_a),
        .read_data_b(read_data_b),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    task check_reads;
        input [31:0] expected_a;
        input [31:0] expected_b;
        begin
            if ({read_data_a, read_data_b} !== {expected_a, expected_b})
                $fatal(1, "Read [%0d,%0d] got %h,%h expected %h,%h",
                       read_addr_a, read_addr_b, read_data_a, read_data_b,
                       expected_a, expected_b);
        end
    endtask

    integer index;
    initial begin
        @(posedge clk);
        #1 check_reads(32'd0, 32'd0);

        // Write every address. Both ports read the write address before
        // and after the edge to check synchronous write timing.
        for (index = 0; index < 4; index = index + 1) begin
            @(negedge clk);
            reset = 1'b0;
            write_enable = 1'b1;
            write_addr = index[1:0];
            write_data = 32'hA5FF_0000 + index;
            read_addr_a = write_addr;
            read_addr_b = write_addr;
            #1 check_reads(32'd0, 32'd0);
            @(posedge clk);
            #1 check_reads(write_data, write_data);
        end

        @(negedge clk);
        write_enable = 1'b0;
        write_data = 32'hDEAD_BEEF;
        read_addr_a = 2'd3;
        read_addr_b = 2'd0;
        #1 check_reads(32'hA5FF_0003, 32'hA5FF_0000);
        @(posedge clk);
        #1 check_reads(32'hA5FF_0003, 32'hA5FF_0000);

        // Reset takes priority over a write and only acts on a rising edge.
        @(negedge clk);
        reset = 1'b1;
        write_enable = 1'b1;
        #1 check_reads(32'hA5FF_0003, 32'hA5FF_0000);
        @(posedge clk);
        #1 check_reads(32'd0, 32'd0);
        read_addr_a = 2'd1;
        read_addr_b = 2'd2;
        #1 check_reads(32'd0, 32'd0);

        $display("PASS tb_vector_regfile");
        $finish;
    end
endmodule
