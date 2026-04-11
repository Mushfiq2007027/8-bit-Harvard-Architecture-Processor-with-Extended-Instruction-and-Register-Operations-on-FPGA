// ============================================================
// cpu_tb.v — Full CPU testbench (multi-cycle harvard_cpu)
// ============================================================
`timescale 1ns/1ps

module cpu_tb;

    reg        clk;
    reg        reset;
    wire [7:0] pc;
    wire [7:0] instr;
    wire [7:0] alu_result;
    wire [3:0] flags;

    harvard_cpu uut (
        .clk           (clk),
        .reset         (reset),
        .imm_sw        (8'h00),
        .ext_rf_we     (1'b0),
        .ext_rf_waddr  (2'b00),
        .ext_rf_wdata  (8'h00),
        .pc_q          (pc),
        .ir_out        (instr),
        .result_display(alu_result),
        .proc_state_led(),
        .flags_zcvs    (flags),
        .cpu_halted    ()
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #20;
        reset = 0;

        $display("==========================================================");
        $display(" CPU Test — 5-stage Harvard CPU (multi-cycle)");
        $display("==========================================================");
        $display(" Time | PC   | Instr | ALUResult | Flags(ZCVS)");

        $monitor("%5t | 0x%02h | 0x%02h  | 0x%02h      | %b%b%b%b",
            $time, pc, instr, alu_result,
            flags[3], flags[2], flags[1], flags[0]);

        #5000;
        $display("==========================================================");
        $finish;
    end

endmodule
