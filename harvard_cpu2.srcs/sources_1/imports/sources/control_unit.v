// ============================================================
// control_unit.v — Decodes 8-bit instructions for Harvard CPU
//
// Format: [opcode 7:4][Rd 3:2][Rs 1:0]
//
// Memory opcode 1110:
//   rd==00           → STORE MEM[Rs] = Rd_reg
//   rd!=00, rs!=11   → LOAD  Rd = MEM[Rs]
//   rd!=00, rs==11   → LDI   Rd = imm_sw[7:0] (immediate from switches)
//
// Branch / system 1111:
//   instruction==0xFF → HALT
//   else: branch using Rd[1:0] as type, Rs = register holding target address
//     00 JMP  PC = R[Rs]
//     01 BEQ  if Z  PC = R[Rs]
//     10 BNE  if !Z PC = R[Rs]
//     11 BMI  if S  PC = R[Rs]
//
// Extended ALU (same primary opcode, Rs pattern):
//   0111: rs==11 → CLR Rd; else NOT Rd
//   1000: rs==11 → CUBE(Rd); else SHL Rd
//   1001: rs==11 → SQR(Rd);  else SHR Rd
//   1010: rs==00 → ASHR Rd;  else DIV Rd, Rs
//
// alu_op[4:0] to ALU:
//   0-13 = ADD..MUL (base ops), 14 DIV, 15 SQR, 16 CUBE, 17 CLR
//   18 PASS_B (internal), 19 ZERO
// ============================================================
`timescale 1ns/1ps

module control_unit(
    input  [7:0] instruction,

    output reg [4:0] alu_op,
    output reg [1:0] rd,
    output reg [1:0] rs,

    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       mem_to_reg,
    output reg       halt,
    output reg       is_branch,
    output reg [1:0] branch_type,
    output reg       is_ldi
);

    wire [3:0] op = instruction[7:4];

    always @(*) begin
        rd         = instruction[3:2];
        rs         = instruction[1:0];
        alu_op     = 5'b10001; // safe default (ZERO)
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        halt       = 1'b0;
        is_branch  = 1'b0;
        branch_type= 2'b00;
        is_ldi     = 1'b0;

        if (instruction == 8'hFF) begin
            halt = 1'b1;
        end
        else if (op == 4'b1111) begin
            is_branch   = 1'b1;
            branch_type = rd;
        end
        else if (op == 4'b1110) begin
            if (rd == 2'b00) begin
                mem_write = 1'b1;
            end
            else if (rs == 2'b11) begin
                is_ldi    = 1'b1;
                reg_write = 1'b1;
                alu_op    = 5'b10101;
            end
            else begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 5'b10100;
            end
        end
        else begin
            case (op)
                4'b0000: begin alu_op = 5'b00000; reg_write = 1'b1; end
                4'b0001: begin alu_op = 5'b00001; reg_write = 1'b1; end
                4'b0010: begin alu_op = 5'b00010; reg_write = 1'b1; end
                4'b0011: begin alu_op = 5'b00011; reg_write = 1'b1; end
                4'b0100: begin alu_op = 5'b00100; reg_write = 1'b1; end
                4'b0101: begin alu_op = 5'b00101; reg_write = 1'b1; end
                4'b0110: begin alu_op = 5'b00110; reg_write = 1'b1; end
                4'b0111: begin
                    reg_write = 1'b1;
                    alu_op = (rs == 2'b11) ? 5'b10001 : 5'b00111;
                end
                4'b1000: begin
                    reg_write = 1'b1;
                    alu_op = (rs == 2'b11) ? 5'b10000 : 5'b01000;
                end
                4'b1001: begin
                    reg_write = 1'b1;
                    alu_op = (rs == 2'b11) ? 5'b01111 : 5'b01001;
                end
                4'b1010: begin
                    reg_write = 1'b1;
                    alu_op = (rs == 2'b00) ? 5'b01010 : 5'b01110;
                end
                4'b1011: begin alu_op = 5'b01011; reg_write = 1'b1; end
                4'b1100: begin alu_op = 5'b01100; reg_write = 1'b1; end
                4'b1101: begin alu_op = 5'b01101; reg_write = 1'b1; end
                default: begin
                    reg_write = 1'b0;
                end
            endcase
        end
    end

endmodule
