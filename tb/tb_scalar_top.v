`timescale 1ns/1ps

module tb_scalar_top;
    reg clk=0;
    always #5 clk=~clk;
    reg reset=1,start=0,we=0;
    reg [2:0] opcode=0;
    reg [1:0] sa=0,sb=1,dst=2,wa=0,ra=0;
    reg [31:0] wd=0;
    wire [31:0] rd;
    wire busy,done;
    integer checks=0,op,n,k;
    reg [31:0] a,b;
    scalar_top dut(.clk(clk),.reset(reset),.start(start),.opcode(opcode),
        .src_a(sa),.src_b(sb),.dst(dst),.host_write_enable(we),
        .host_write_addr(wa),.host_write_data(wd),.host_read_addr(ra),
        .host_read_data(rd),.busy(busy),.done(done));
    function [31:0] model;
        input [31:0] x,y;
        input [2:0] operation;
        integer lane;
        reg [7:0] u,v,r;
        begin
            for(lane=0;lane<4;lane=lane+1) begin
                u=x[lane*8 +: 8];v=y[lane*8 +: 8];
                case(operation)
                    0:r=u+v;1:r=u-v;2:r=u&v;3:r=u|v;
                    4:r=u<v ? 8'd1:8'd0;default:r=0;
                endcase
                model[lane*8 +: 8]=r;
            end
        end
    endfunction
    task flags;
        input eb,ed;
        begin
            checks=checks+1;
            if({busy,done} !== {eb,ed}) $fatal(1,"Handshake mismatch");
        end
    endtask
    task inspect;
        input [1:0] address;
        input [31:0] expected;
        begin
            ra=address;#1;checks=checks+1;
            if(rd !== expected) $fatal(1,"R%0d got %h expected %h",address,rd,expected);
        end
    endtask
    task load_vector;
        input [1:0] address;
        input [31:0] value;
        begin
            @(negedge clk);start=0;we=1;wa=address;wd=value;
            @(posedge clk);#1;inspect(address,value);
            @(negedge clk);we=0;
        end
    endtask
    task execute;
        input [2:0] operation;
        input [1:0] destination;
        input [31:0] expected;
        integer edge_index;
        begin
            @(negedge clk);sa=0;sb=1;dst=destination;opcode=operation;start=1;
            we=1;wa=3;wd=32'hDEADBEEF;
            @(posedge clk);#1;flags(1,0);
            @(negedge clk);sa=3;sb=3;dst=3;opcode=7;
            for(edge_index=0;edge_index<4;edge_index=edge_index+1) begin
                @(posedge clk);#1;flags(1,0);
            end
            @(posedge clk);#1;flags(0,1);
            @(negedge clk);start=0;we=0;
            inspect(destination,expected);inspect(3,32'h12345678);
            @(posedge clk);#1;flags(0,0);
        end
    endtask
    initial begin
        $dumpfile("tb_scalar_top.vcd");$dumpvars(0,tb_scalar_top);
        @(posedge clk);#1;flags(0,0);
        inspect(0,0);inspect(1,0);inspect(2,0);inspect(3,0);
        @(negedge clk);reset=0;
        load_vector(3,32'h12345678);
        a=32'hFF800003;b=32'h0180FF05;
        load_vector(0,a);load_vector(1,b);
        execute(0,2,32'h0000FF08);execute(1,2,32'hFE0001FE);
        execute(2,2,32'h01800001);execute(3,2,32'hFF80FF07);
        execute(4,2,32'h00000101);
        for(op=5;op<8;op=op+1) execute(op[2:0],2,0);
        execute(0,0,32'h0000FF08);inspect(1,b);
        $dumpoff;
        for(n=0;n<32;n=n+1) begin
            a=$random;b=$random;load_vector(0,a);load_vector(1,b);
            for(op=0;op<8;op=op+1) execute(op[2:0],2,model(a,b,op[2:0]));
        end
        // Cancel before each element execution and before writeback.
        for(n=0;n<5;n=n+1) begin
            load_vector(0,32'hFFFFFFFF);
            @(negedge clk);start=1;sa=0;sb=0;dst=2;opcode=0;
            @(posedge clk);#1;flags(1,0);
            for(k=0;k<n;k=k+1) begin
                @(negedge clk);start=0;
                @(posedge clk);#1;flags(1,0);
            end
            @(negedge clk);reset=1;start=0;
            @(posedge clk);#1;flags(0,0);
            inspect(0,0);inspect(1,0);inspect(2,0);inspect(3,0);
            @(negedge clk);reset=0;
        end
        $display("PASS tb_scalar_top: %0d checks",checks);$finish;
    end
    initial begin #100000;$fatal(1,"Timeout");end
endmodule
