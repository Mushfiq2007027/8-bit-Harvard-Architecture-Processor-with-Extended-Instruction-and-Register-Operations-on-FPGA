// ============================================================
// harvard_cpu.v — 5-stage multi-cycle Harvard CPU
// Stages: FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK
// ============================================================
`timescale 1ns/1ps

module harvard_cpu(
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] imm_sw,
    input  wire       ext_rf_we,
    input  wire [1:0] ext_rf_waddr,
    input  wire [7:0] ext_rf_wdata,

    output reg  [7:0] pc_q,
    output reg  [7:0] ir_out,
    output reg  [7:0] result_display,
    output reg  [3:0] proc_state_led,
    output wire [3:0] flags_zcvs,
    output wire       cpu_halted
);

    localparam ST_FETCH     = 4'd0;
    localparam ST_DECODE    = 4'd1;
    localparam ST_EXECUTE   = 4'd2;
    localparam ST_MEMORY    = 4'd3;
    localparam ST_WRITEBACK = 4'd4;
    localparam ST_HALTED    = 4'd5;

    reg  [3:0] state;
    reg  [7:0] ir;
    reg  [7:0] alu_result_r;
    reg        exec_z, exec_c, exec_v, exec_s;
    reg  [3:0] flag_reg;

    wire [7:0] instr_mem_out;
    wire [4:0] alu_op;
    wire [1:0] rd_f, rs_f;
    wire       reg_write_id, mem_read_id, mem_write_id, mem_to_reg_id;
    wire       halt_id, is_branch_id, is_ldi_id;
    wire [1:0] branch_type_id;

    wire [7:0] rs_val;
    wire [7:0] rd_val;
    wire [7:0] alu_res;
    wire       Z_alu, C_alu, V_alu, S_alu;
    wire [7:0] dmem_rdata;

    wire mem_read_x  = (state == ST_MEMORY) && mem_read_id;
    wire mem_write_x = (state == ST_MEMORY) && mem_write_id;
    wire rf_we_cpu   = (state == ST_WRITEBACK) && reg_write_id;

    reg  [7:0] wb_data;
    wire alu_flag_en = reg_write_id && !mem_to_reg_id && !is_ldi_id && !is_branch_id;

    instruction_memory imem (
        .addr (pc_q),
        .instr(instr_mem_out)
    );

    data_memory dmem (
        .clk       (clk),
        .mem_write (mem_write_x),
        .mem_read  (mem_read_x),
        .addr      (rs_val),
        .write_data(rd_val),
        .read_data (dmem_rdata)
    );

    register_file rf (
        .clk           (clk),
        .reset         (reset),
        .write_enable  (rf_we_cpu),
        .read_addr1    (rs_f),
        .read_addr2    (rd_f),
        .write_addr    (rd_f),
        .write_data    (wb_data),
        .read_data1    (rs_val),
        .read_data2    (rd_val),
        .ext_write     (ext_rf_we),
        .ext_waddr     (ext_rf_waddr),
        .ext_wdata     (ext_rf_wdata)
    );

    control_unit cu (
        .instruction (ir),
        .alu_op      (alu_op),
        .rd          (rd_f),
        .rs          (rs_f),
        .reg_write   (reg_write_id),
        .mem_read    (mem_read_id),
        .mem_write   (mem_write_id),
        .mem_to_reg  (mem_to_reg_id),
        .halt        (halt_id),
        .is_branch   (is_branch_id),
        .branch_type (branch_type_id),
        .is_ldi      (is_ldi_id)
    );

    alu alu_inst (
        .A      (rd_val),
        .B      (rs_val),
        .opcode (alu_op),
        .result (alu_res),
        .Z      (Z_alu),
        .C      (C_alu),
        .V      (V_alu),
        .S      (S_alu)
    );

    wire Zf = flag_reg[3];
    wire Sf = flag_reg[0];

    reg [7:0] next_pc;
    always @(*) begin
        next_pc = pc_q + 8'd1;
        if (is_branch_id) begin
            case (branch_type_id)
                2'b00: next_pc = rs_val;
                2'b01: next_pc = Zf  ? rs_val : (pc_q + 8'd1);
                2'b10: next_pc = !Zf ? rs_val : (pc_q + 8'd1);
                2'b11: next_pc = Sf  ? rs_val : (pc_q + 8'd1);
                default: next_pc = pc_q + 8'd1;
            endcase
        end
    end

    always @(*) begin
        if (mem_to_reg_id)
            wb_data = dmem_rdata;
        else if (is_ldi_id)
            wb_data = imm_sw;
        else
            wb_data = alu_result_r;
    end

    assign flags_zcvs = flag_reg;
    assign cpu_halted = (state == ST_HALTED);

    always @(*) begin
        if (state == ST_HALTED)
            proc_state_led = 4'b1111;
        else if (state == ST_FETCH)
            proc_state_led = 4'd0;
        else if (state == ST_DECODE)
            proc_state_led = 4'd1;
        else if (state == ST_EXECUTE)
            proc_state_led = 4'd2;
        else if (state == ST_MEMORY)
            proc_state_led = 4'd3;
        else if (state == ST_WRITEBACK)
            proc_state_led = 4'd4;
        else
            proc_state_led = 4'd0;
    end

    always @(posedge clk) begin
        if (reset) begin
            state          <= ST_FETCH;
            pc_q           <= 8'h00;
            ir             <= 8'h00;
            ir_out         <= 8'h00;
            alu_result_r   <= 8'h00;
            result_display <= 8'h00;
            exec_z <= 0; exec_c <= 0; exec_v <= 0; exec_s <= 0;
            flag_reg       <= 4'b0000;
        end
        else begin
            case (state)
                ST_FETCH: begin
                    ir     <= instr_mem_out;
                    ir_out <= instr_mem_out;
                    if (instr_mem_out == 8'hFF)
                        state <= ST_HALTED;
                    else
                        state <= ST_DECODE;
                end

                ST_DECODE: begin
                    state <= ST_EXECUTE;
                end

                ST_EXECUTE: begin
                    alu_result_r   <= alu_res;
                    result_display <= alu_res;
                    if (alu_flag_en) begin
                        exec_z <= Z_alu;
                        exec_c <= C_alu;
                        exec_v <= V_alu;
                        exec_s <= S_alu;
                    end
                    state <= ST_MEMORY;
                end

                ST_MEMORY: begin
                    state <= ST_WRITEBACK;
                end

                ST_WRITEBACK: begin
                    if (reg_write_id) begin
                        if (mem_to_reg_id || is_ldi_id) begin
                            flag_reg[3] <= (wb_data == 8'h00);
                            flag_reg[0] <= wb_data[7];
                        end
                        else begin
                            flag_reg <= {exec_z, exec_c, exec_v, exec_s};
                        end
                    end
                    pc_q <= next_pc;
                    state <= ST_FETCH;
                end

                ST_HALTED: ;

                default: state <= ST_FETCH;
            endcase
        end
    end

endmodule
