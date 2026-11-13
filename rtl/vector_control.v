`timescale 1ns/1ps

module vector_control (
    input  wire clk,
    input  wire reset,
    input  wire start,
    output wire busy,
    output wire write_enable,
    output reg  done
);
    localparam [1:0] IDLE = 2'd0,
                     EXECUTE = 2'd1,
                     WRITEBACK = 2'd2;

    reg [1:0] state;

    assign busy = (state == EXECUTE) || (state == WRITEBACK);
    assign write_enable = (state == WRITEBACK);

    // Sample start in IDLE. The register file writes on the edge that
    // leaves WRITEBACK. Done is high for the following cycle in IDLE.
    // Synchronous reset cancels writeback through the register file reset.
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done  <= 1'b0;
        end else begin
            done <= write_enable;
            case (state)
                IDLE: begin
                    if (start)
                        state <= EXECUTE;
                end
                EXECUTE:   state <= WRITEBACK;
                WRITEBACK: state <= IDLE;
                default:   state <= IDLE;
            endcase
        end
    end
endmodule
