`timescale 1ns/1ps
module tb_simd_top;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, start = 0;
    reg [2:0] opcode = 0;
    reg [1:0] src_a = 0, src_b = 1, dst = 2;
    reg host_write_enable = 0;
    reg [1:0] host_write_addr = 0, host_read_addr = 0;
    reg [31:0] host_write_data = 0;
    wire [31:0] host_read_data;
    wire busy, done;
    integer checks = 0, op, n;
    reg [31:0] a, b;

    simd_top dut (
        .clk(clk), .reset(reset), .start(start), .opcode(opcode),
        .src_a(src_a), .src_b(src_b), .dst(dst),
        .host_write_enable(host_write_enable),
        .host_write_addr(host_write_addr), .host_write_data(host_write_data),
        .host_read_addr(host_read_addr), .host_read_data(host_read_data),
        .busy(busy), .done(done)
    );

    function [31:0] reference_vector;
        input [31:0] x, y;
        input [2:0] operation;
        reg [7:0] u, v, r;
        integer lane;
        begin
            for (lane = 0; lane < 4; lane = lane + 1) begin
                u = x[lane*8 +: 8]; v = y[lane*8 +: 8];
                case (operation)
                    0: r = u + v;
                    1: r = u - v;
                    2: r = u & v;
                    3: r = u | v;
                    4: r = u < v ? 8'd1 : 8'd0;
                    default: r = 0;
                endcase
                reference_vector[lane*8 +: 8] = r;
            end
        end
    endfunction

    task flags;
        input expected_busy, expected_done;
        begin
            checks = checks + 1;
            if ({busy,done} !== {expected_busy,expected_done})
                $fatal(1, "Unexpected handshake at %0t", $time);
        end
    endtask

    task read_check;
        input [1:0] address;
        input [31:0] expected;
        begin
            host_read_addr = address;
            #1;
            checks = checks + 1;
            if (host_read_data !== expected)
                $fatal(1, "R%0d got %h expected %h", address, host_read_data, expected);
        end
    endtask

    task load_vector;
        input [1:0] address;
        input [31:0] value;
        begin
            @(negedge clk);
            start = 0; host_write_enable = 1;
            host_write_addr = address; host_write_data = value;
            @(posedge clk); #1;
            read_check(address, value);
            @(negedge clk); host_write_enable = 0;
        end
    endtask

    task execute_check;
        input [2:0] operation;
        input [1:0] destination;
        input [31:0] expected;
        begin
            @(negedge clk);
            src_a = 0; src_b = 1; dst = destination;
            opcode = operation; start = 1;
            // A simultaneous host write must lose to start.
            host_write_enable = 1; host_write_addr = 3;
            host_write_data = 32'hDEADBEEF;
            @(posedge clk); #1; flags(1,0);
            // Mutate all instruction inputs and attempt writes while busy.
            // Captured operands/opcode/destination must remain unaffected.
            @(negedge clk);
            src_a = 3; src_b = 3; dst = 3; opcode = 7;
            @(posedge clk); #1; flags(1,0);
            @(posedge clk); #1; flags(0,1);
            // start was high in both busy states; neither request is queued.
            @(negedge clk); start = 0; host_write_enable = 0;
            read_check(destination, expected);
            read_check(3, 32'h12345678);
            @(posedge clk); #1; flags(0,0);
        end
    endtask

    initial begin
        $dumpfile("tb_simd_top.vcd");
        $dumpvars(0, tb_simd_top);
        @(posedge clk); #1; flags(0,0);
        read_check(0,0); read_check(1,0);
        read_check(2,0); read_check(3,0);
        @(negedge clk); reset = 0;
        load_vector(3,32'h12345678);

        // Distinct lanes include carry, borrow, equality and unsigned boundaries.
        a = 32'hFF800003; b = 32'h0180FF05;
        load_vector(0,a); load_vector(1,b);
        execute_check(0,2,32'h0000FF08);
        execute_check(1,2,32'hFE0001FE);
        execute_check(2,2,32'h01800001);
        execute_check(3,2,32'hFF80FF07);
        execute_check(4,2,32'h00000101);
        for (op = 5; op < 8; op = op + 1)
            execute_check(op[2:0],2,0);

        // In-place destination exercises operand capture before writeback.
        execute_check(0,0,32'h0000FF08);
        read_check(1,b);

        // Random vectors exercise every opcode with independent lane values.
        $dumpoff;
        for (n = 0; n < 32; n = n + 1) begin
            a = $random; b = $random;
            load_vector(0,a); load_vector(1,b);
            for (op = 0; op < 8; op = op + 1)
                execute_check(op[2:0],2,reference_vector(a,b,op[2:0]));
        end

        // Reset cancels an operation in each busy state and clears storage.
        for (n = 0; n < 2; n = n + 1) begin
            load_vector(0,32'hFFFFFFFF);
            @(negedge clk); start = 1; src_a = 0; src_b = 0; dst = 2; opcode = 0;
            @(posedge clk); #1; flags(1,0);
            if (n == 1) begin
                @(negedge clk); start = 0;
                @(posedge clk); #1; flags(1,0);
            end
            @(negedge clk); reset = 1; start = 0;
            @(posedge clk); #1; flags(0,0);
            read_check(0,0); read_check(1,0);
            read_check(2,0); read_check(3,0);
            @(negedge clk); reset = 0;
        end
        $display("PASS tb_simd_top: %0d checks",checks);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1,"Simulation timeout");
    end
endmodule
