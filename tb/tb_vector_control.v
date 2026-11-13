`timescale 1ns/1ps

module tb_vector_control;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg reset = 1'b1;
    reg start = 1'b0;
    wire busy;
    wire write_enable;
    wire done;

    vector_control dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .busy(busy),
        .write_enable(write_enable),
        .done(done)
    );

    task check_outputs;
        input [2:0] expected;
        begin
            if ({busy, write_enable, done} !== expected)
                $fatal(1, "At %0t busy/write_enable/done = %b%b%b, expected %b",
                       $time, busy, write_enable, done, expected);
        end
    endtask

    task step;
        input next_reset;
        input next_start;
        input [2:0] expected;
        begin
            @(negedge clk);
            reset = next_reset;
            start = next_start;
            @(posedge clk);
            #1 check_outputs(expected);
        end
    endtask

    initial begin
        @(posedge clk);
        #1 check_outputs(3'b000);
        step(1'b0, 1'b0, 3'b000); // Idle without start.
        step(1'b0, 1'b1, 3'b100); // Accept start and enter EXECUTE.
        step(1'b0, 1'b1, 3'b110); // Ignore start in EXECUTE.
        step(1'b0, 1'b1, 3'b001); // Ignore start in WRITEBACK. Write and pulse done.
        step(1'b0, 1'b0, 3'b000); // Clear done. Busy starts were discarded.

        step(1'b0, 1'b1, 3'b100);
        step(1'b1, 1'b1, 3'b000); // Reset in EXECUTE takes priority over start.
        step(1'b0, 1'b1, 3'b100);
        step(1'b0, 1'b0, 3'b110);
        step(1'b1, 1'b0, 3'b000); // Reset in WRITEBACK suppresses done.

        step(1'b0, 1'b1, 3'b100);
        step(1'b0, 1'b0, 3'b110);
        step(1'b0, 1'b0, 3'b001);
        step(1'b0, 1'b1, 3'b100); // Accept start on the first idle edge.
        step(1'b0, 1'b0, 3'b110);
        step(1'b0, 1'b0, 3'b001);
        step(1'b1, 1'b0, 3'b000); // Reset also clears an active done pulse.

        $display("PASS tb_vector_control");
        $finish;
    end
endmodule
