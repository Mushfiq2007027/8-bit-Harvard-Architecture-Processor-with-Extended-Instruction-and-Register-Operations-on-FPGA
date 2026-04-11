// ============================================================
// alu_tb.v — Testbench for alu.v (5-bit opcode)
// ============================================================
`timescale 1ns/1ps

module alu_tb;

    reg  [7:0] A, B;
    reg  [4:0] opcode;
    wire [7:0] result;
    wire       Z, C, V, S;

    alu uut (
        .A(A), .B(B), .opcode(opcode),
        .result(result), .Z(Z), .C(C), .V(V), .S(S)
    );

    initial begin
        $display("==========================================================");
        $display(" ALU Test — 5-bit opcodes");
        $display("==========================================================");

        A=8'd10; B=8'd5; opcode=5'b00000; #10;
        $display("ADD:  10 + 5 = %0d  (expect 15)", result);

        A=8'hFF; B=8'h01; opcode=5'b00000; #10;
        $display("ADD:  0xFF + 0x01 = 0x%02h  C=%b Z=%b", result, C, Z);

        A=8'd10; B=8'd3; opcode=5'b00001; #10;
        $display("SUB:  10 - 3 = %0d", result);

        A=8'd7; B=8'd0; opcode=5'b00010; #10;
        $display("INC:  7 + 1 = %0d", result);

        A=8'd7; B=8'd0; opcode=5'b00011; #10;
        $display("DEC:  7 - 1 = %0d", result);

        A=8'b10101010; B=8'b11001100; opcode=5'b00100; #10;
        $display("AND:  result=0b%08b", result);

        A=8'b10101010; B=8'b11001100; opcode=5'b00101; #10;
        $display("OR:   result=0b%08b", result);

        A=8'b10101010; B=8'b11001100; opcode=5'b00110; #10;
        $display("XOR:  result=0b%08b", result);

        A=8'b10101010; B=8'd0; opcode=5'b00111; #10;
        $display("NOT:  result=0b%08b", result);

        A=8'b00001111; B=8'd0; opcode=5'b01000; #10;
        $display("SHL:  result=0b%08b  C=%b", result, C);

        A=8'b00001111; B=8'd0; opcode=5'b01001; #10;
        $display("SHR:  result=0b%08b  C=%b", result, C);

        A=8'b10001111; B=8'd0; opcode=5'b01010; #10;
        $display("ASHR: result=0b%08b", result);

        A=8'b10001111; B=8'd0; opcode=5'b01011; #10;
        $display("ROL:  result=0b%08b", result);

        A=8'b10001111; B=8'd0; opcode=5'b01100; #10;
        $display("ROR:  result=0b%08b", result);

        A=8'd4; B=8'd3; opcode=5'b01101; #10;
        $display("MUL:  4 * 3 = %0d", result);

        A=8'd20; B=8'd4; opcode=5'b01110; #10;
        $display("DIV:  20 / 4 = %0d", result);

        A=8'd5; B=8'd0; opcode=5'b01111; #10;
        $display("SQR:  5^2 lower 8 = %0d", result);

        A=8'd3; B=8'd0; opcode=5'b10000; #10;
        $display("CUBE: 3^3 lower 8 = %0d", result);

        A=8'hFF; B=8'd0; opcode=5'b10001; #10;
        $display("CLR:  result=0x%02h Z=%b", result, Z);

        A=8'd0; B=8'hAB; opcode=5'b10100; #10;
        $display("PASS_B: result=0x%02h", result);

        $display("==========================================================");
        $finish;
    end

endmodule
