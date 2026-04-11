// ============================================================
// top_module.v — Basys3 top-level (8-bit Harvard multi-cycle CPU)
//
// SW[15:8]  Manual data byte (written to register on BTND)
// SW[7:0]   Immediate byte for LDI instruction (opcode Ex 11)
// SW[5:4]   CPU clock: 00=slow 01=med 10=fast 11=single-step via BTNC
// SW[12]    Manual flag override enable
// SW[11:8]  Manual {Z,C,V,S} when override enabled
//
// BTNC      Single-step pulse when SW[5:4]=11
// BTNU      Reset
// BTNL      OR into Z when flag override enabled (manual flag assist)
// BTNR      OR into S when flag override enabled
// BTND      Load SW[15:8] into register R[SW[1:0]]
//
// LED[7:0]   Current instruction register (IR)
// LED[11:8]  Flags {Z,C,V,S}
// LED[15:12] Pipeline state: 0=FETCH..4=WB, F=halted
// ============================================================

`timescale 1ns/1ps

module top_module(
    input        clk,
    input        reset,
    input  [15:0] SW,
    input        BTNC,
    input        BTNL,
    input        BTNR,
    input        BTND,
    output [15:0] LED,
    output [6:0]  seg,
    output [3:0]  an,
    output        dp
);

    wire slow_clk, med_clk, fast_clk;
    reg  cpu_clk;
    reg  btnc_prev;
    reg  btnd_d1, btnd_d2, btnd_d3;
    wire step_pulse = BTNC & ~btnc_prev;

    wire [7:0] pc_val;
    wire [7:0] instr_led;
    wire [7:0] alu_disp;
    wire [3:0] pipe_led;
    wire [3:0] flags_cpu;
    wire       halted;

    wire Z_alu = flags_cpu[3];
    wire C_alu = flags_cpu[2];
    wire V_alu = flags_cpu[1];
    wire S_alu = flags_cpu[0];

    wire ovrd_en = SW[12];
    wire Z_flag  = ovrd_en ? (SW[11] | BTNL) : Z_alu;
    wire C_flag  = ovrd_en ?  SW[10]         : C_alu;
    wire V_flag  = ovrd_en ?  SW[9]          : V_alu;
    wire S_flag  = ovrd_en ? (SW[8]  | BTNR) : S_alu;

    clock_divider clk_div_inst (
        .clk      (clk),
        .reset    (reset),
        .slow_clk (slow_clk),
        .med_clk  (med_clk),
        .fast_clk (fast_clk)
    );

    always @(posedge clk) begin
        btnc_prev <= BTNC;
    end

    always @(posedge cpu_clk or posedge reset) begin
        if (reset) begin
            btnd_d1 <= 1'b0;
            btnd_d2 <= 1'b0;
            btnd_d3 <= 1'b0;
        end
        else begin
            btnd_d1 <= BTND;
            btnd_d2 <= btnd_d1;
            btnd_d3 <= btnd_d2;
        end
    end
    wire btnd_cpu_edge = btnd_d2 & ~btnd_d3;

    always @(*) begin
        case (SW[5:4])
            2'b00: cpu_clk = slow_clk;
            2'b01: cpu_clk = med_clk;
            2'b10: cpu_clk = fast_clk;
            2'b11: cpu_clk = step_pulse;
            default: cpu_clk = slow_clk;
        endcase
    end

    harvard_cpu cpu (
        .clk           (cpu_clk),
        .reset         (reset),
        .imm_sw        (SW[7:0]),
        .ext_rf_we     (btnd_cpu_edge),
        .ext_rf_waddr  (SW[1:0]),
        .ext_rf_wdata  (SW[15:8]),
        .pc_q          (pc_val),
        .ir_out        (instr_led),
        .result_display(alu_disp),
        .proc_state_led(pipe_led),
        .flags_zcvs    (flags_cpu),
        .cpu_halted    (halted)
    );

    assign LED[7:0]   = instr_led;
    assign LED[11:8]  = {Z_flag, C_flag, V_flag, S_flag};
    assign LED[15:12]= pipe_led;

    seven_seg_display ssd (
        .clk       (clk),
        .reset     (reset),
        .pc_val    (pc_val),
        .alu_result(alu_disp),
        .an        (an),
        .seg       (seg)
    );

    assign dp = 1'b1;

endmodule
