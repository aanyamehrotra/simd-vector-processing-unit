`timescale 1ns/1ps

// Matched resident-vector workloads; loading/inspection excluded from timing.
module tb_performance;
    localparam N=16;
    reg clk=0;
    always #5 clk=~clk;
    reg reset=1,vs=0,ss=0,we=0;
    reg [2:0] opcode=0;
    reg [1:0] wa=0,ra=0;
    reg [31:0] wd=0;
    wire [31:0] vr,sr;
    wire vb,sb,vd,sd;
    integer cycle=0,op,trial,fd;
    integer vi,si,vc,sc,vfirst,sfirst,vlast,slast,vlat,slat;
    reg [31:0] a,b,expected;
    simd_top vector_dut(.clk(clk),.reset(reset),.start(vs),.opcode(opcode),
        .src_a(2'd0),.src_b(2'd1),.dst(2'd2),.host_write_enable(we),
        .host_write_addr(wa),.host_write_data(wd),.host_read_addr(ra),
        .host_read_data(vr),.busy(vb),.done(vd));
    scalar_top scalar_dut(.clk(clk),.reset(reset),.start(ss),.opcode(opcode),
        .src_a(2'd0),.src_b(2'd1),.dst(2'd2),.host_write_enable(we),
        .host_write_addr(wa),.host_write_data(wd),.host_read_addr(ra),
        .host_read_data(sr),.busy(sb),.done(sd));
    always @(posedge clk) cycle <= cycle+1;
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
    task load_both;
        input [1:0] address;
        input [31:0] value;
        begin
            @(negedge clk);we=1;wa=address;wd=value;ra=address;
            @(posedge clk);#1;
            if(vr !== value || sr !== value) $fatal(1,"Load mismatch");
            @(negedge clk);we=0;
        end
    endtask
    task benchmark;
        input [2:0] operation;
        reg vacc,sacc;
        begin
            opcode=operation;expected=model(a,b,operation);
            vi=0;si=0;vc=0;sc=0;
            while(vc<N || sc<N) begin
                @(negedge clk);vs=(!vb && vi<N);ss=(!sb && si<N);
                vacc=vs && !vb;sacc=ss && !sb;
                @(posedge clk);#1;
                if(vacc) begin if(vi==0) vfirst=cycle;vi=vi+1;end
                if(sacc) begin if(si==0) sfirst=cycle;si=si+1;end
                // Release shared read-port A to inspect destination register.
                vs=0;ss=0;ra=2;#1;
                if(vd) begin
                    if(vr !== expected) $fatal(1,"SIMD mismatch");
                    if(vc==0) vlat=cycle-vfirst;
                    vc=vc+1;vlast=cycle;
                end
                if(sd) begin
                    if(sr !== expected) $fatal(1,"Scalar mismatch");
                    if(sc==0) slat=cycle-sfirst;
                    sc=sc+1;slast=cycle;
                end
            end
            if(vi!=N || si!=N) $fatal(1,"Request count mismatch");
            if(vlat!=2 || slat!=5) $fatal(1,"Latency mismatch");
            if(vlast-vfirst!=3*N-1 || slast-sfirst!=6*N-1)
                $fatal(1,"Batch schedule mismatch");
            $display("op=%0d vectors=%0d SIMD=%0d scalar=%0d cycles speedup=%0.6f",
                operation,N,vlast-vfirst,slast-sfirst,
                1.0*(slast-sfirst)/(vlast-vfirst));
            $fdisplay(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0.6f",trial,
                operation,N,vlat,slat,vlast-vfirst,slast-sfirst,4*N,
                1.0*(slast-sfirst)/(vlast-vfirst));
        end
    endtask
    initial begin
        $dumpfile("tb_performance.vcd");$dumpvars(0,tb_performance);
        fd=$fopen("performance.csv","w");
        if(fd==0) $fatal(1,"Cannot create performance.csv");
        $fdisplay(fd,"trial,opcode,vectors,simd_latency_cycles,scalar_latency_cycles,simd_batch_cycles,scalar_batch_cycles,elements,speedup");
        @(posedge clk);#1;@(negedge clk);reset=0;
        for(trial=0;trial<5;trial=trial+1) begin
            if(trial==0) begin a=32'hFF800003;b=32'h0180FF05;end
            else begin a=$random;b=$random;end
            load_both(0,a);load_both(1,b);
            for(op=0;op<5;op=op+1) benchmark(op[2:0]);
            $dumpoff;
        end
        $fclose(fd);
        $display("PASS tb_performance: 25 batches, 400 vectors per architecture");
        $finish;
    end
    initial begin #1000000;$fatal(1,"Benchmark timeout");end
endmodule
