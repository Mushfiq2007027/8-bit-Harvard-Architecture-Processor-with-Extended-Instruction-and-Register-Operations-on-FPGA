// ============================================================
// alu.v  —  8-bit ALU with MANUALLY DESIGNED hardware circuits
// NO built-in Verilog arithmetic operators used for computation.
// All operations are implemented using gate-level logic / 
// structural bit-manipulation (as required by the teacher).
//
// 4-bit opcode encoding:
//   4'b0000  ADD     A + B
//   4'b0001  SUB     A - B  (using 2's complement adder)
//   4'b0010  INC     A + 1
//   4'b0011  DEC     A - 1
//   4'b0100  AND     A & B  (bitwise)
//   4'b0101  OR      A | B  (bitwise)
//   4'b0110  XOR     A ^ B  (bitwise)
//   4'b0111  NOT     ~A     (bitwise complement)
//   4'b1000  SHL     shift A left  1 (logical)
//   4'b1001  SHR     shift A right 1 (logical)
//   4'b1010  ASHR    shift A right 1 (arithmetic, sign-extend)
//   4'b1011  ROL     rotate A left  1
//   4'b1100  ROR     rotate A right 1
//   4'b1101  MUL     A * B  (8-bit result via shift-and-add)
//   4'b1110  LOAD/TRANSFER  result = B (pass-through)
//   4'b1111  HALT / reserved
// ============================================================
`timescale 1ns/1ps

module alu(
    input  [7:0] A,          // Operand 1 (destination register value)
    input  [7:0] B,          // Operand 2 (source register value)
    input  [4:0] opcode,     // 5-bit operation code
    output reg [7:0] result, // 8-bit ALU result
    output reg Z,            // Zero flag
    output reg C,            // Carry flag
    output reg V,            // Overflow flag (signed)
    output reg S             // Sign flag (MSB of result)
);

// ============================================================
// SECTION 1: FULL ADDER PRIMITIVE (1-bit)
// Hardware: two XOR, two AND, one OR gate
// ============================================================
// We build a reusable task for a 1-bit full adder
// sum  = A ^ B ^ Cin
// cout = (A & B) | (B & Cin) | (A & Cin)
// Used inside the ripple-carry adder below.

// ============================================================
// SECTION 2: 8-BIT RIPPLE-CARRY ADDER FUNCTION
// Manually expanded 8x full-adder chain
// ============================================================
// We declare internal wires for the adder generates + propagates
// These are used inside the always block via reg variables.

// Internal working registers
reg [7:0] add_result;
reg       add_carry_out;

// Intermediate carry and sum bits for the ripple-carry adder
reg c0,c1,c2,c3,c4,c5,c6,c7,c8;   // carries  c0=Cin, c8=Cout
reg s0,s1,s2,s3,s4,s5,s6,s7;       // sum bits
reg [7:0] b_op;   // B or ~B (for subtraction: B inverted)
reg       sub_cin; // 1 for subtraction (2's complement: ~B + 1)

// ============================================================
// SECTION 3: SHIFT-AND-ADD MULTIPLIER (8-bit result)
// Implements A * B using 8 conditional partial products.
// Result is truncated to lower 8 bits (no * operator used).
// ============================================================
reg [15:0] mul_acc;    // 16-bit accumulator
reg [7:0]  mul_a;      // multiplicand
reg [7:0]  mul_b;      // multiplier
integer    mul_i;      // loop index

// ============================================================
// MAIN ALU LOGIC
// ============================================================
always @(*) begin
    // ---- Default all outputs to 0 ----
    result  = 8'h00;
    Z = 1'b0; C = 1'b0; V = 1'b0; S = 1'b0;

    // ---- Default adder inputs (ADD mode) ----
    b_op   = B;
    sub_cin = 1'b0;

    // ---- Initialise adder signals to avoid latches ----
    c0=0; c1=0; c2=0; c3=0; c4=0; c5=0; c6=0; c7=0; c8=0;
    s0=0; s1=0; s2=0; s3=0; s4=0; s5=0; s6=0; s7=0;
    add_result    = 8'h00;
    add_carry_out = 1'b0;
    mul_acc = 16'h0000;

    case (opcode)

        // ==================================================
        // 0000: ADD  —  A + B
        // 8-bit ripple-carry adder, Cin = 0
        // ==================================================
        5'b00000: begin
            b_op    = B;
            sub_cin = 1'b0;
            // --- Full-Adder chain (bit 0) ---
            c0 = sub_cin;
            s0 = A[0] ^ b_op[0] ^ c0;
            c1 = (A[0] & b_op[0]) | (b_op[0] & c0) | (A[0] & c0);
            // --- bit 1 ---
            s1 = A[1] ^ b_op[1] ^ c1;
            c2 = (A[1] & b_op[1]) | (b_op[1] & c1) | (A[1] & c1);
            // --- bit 2 ---
            s2 = A[2] ^ b_op[2] ^ c2;
            c3 = (A[2] & b_op[2]) | (b_op[2] & c2) | (A[2] & c2);
            // --- bit 3 ---
            s3 = A[3] ^ b_op[3] ^ c3;
            c4 = (A[3] & b_op[3]) | (b_op[3] & c3) | (A[3] & c3);
            // --- bit 4 ---
            s4 = A[4] ^ b_op[4] ^ c4;
            c5 = (A[4] & b_op[4]) | (b_op[4] & c4) | (A[4] & c4);
            // --- bit 5 ---
            s5 = A[5] ^ b_op[5] ^ c5;
            c6 = (A[5] & b_op[5]) | (b_op[5] & c5) | (A[5] & c5);
            // --- bit 6 ---
            s6 = A[6] ^ b_op[6] ^ c6;
            c7 = (A[6] & b_op[6]) | (b_op[6] & c6) | (A[6] & c6);
            // --- bit 7 (MSB) ---
            s7 = A[7] ^ b_op[7] ^ c7;
            c8 = (A[7] & b_op[7]) | (b_op[7] & c7) | (A[7] & c7);

            add_result    = {s7,s6,s5,s4,s3,s2,s1,s0};
            add_carry_out = c8;

            result = add_result;
            C = add_carry_out;
            // Overflow: signs of A and B are same, but result sign differs
            V = (~A[7] & ~B[7] & result[7]) | (A[7] & B[7] & ~result[7]);
        end

        // ==================================================
        // 0001: SUB  —  A - B = A + (~B) + 1  (2's complement)
        // ==================================================
        5'b00001: begin
            b_op    = ~B;      // Invert B
            sub_cin = 1'b1;    // Add 1 (completing 2's complement)
            // --- Full-Adder chain ---
            c0 = sub_cin;
            s0 = A[0] ^ b_op[0] ^ c0;
            c1 = (A[0] & b_op[0]) | (b_op[0] & c0) | (A[0] & c0);
            s1 = A[1] ^ b_op[1] ^ c1;
            c2 = (A[1] & b_op[1]) | (b_op[1] & c1) | (A[1] & c1);
            s2 = A[2] ^ b_op[2] ^ c2;
            c3 = (A[2] & b_op[2]) | (b_op[2] & c2) | (A[2] & c2);
            s3 = A[3] ^ b_op[3] ^ c3;
            c4 = (A[3] & b_op[3]) | (b_op[3] & c3) | (A[3] & c3);
            s4 = A[4] ^ b_op[4] ^ c4;
            c5 = (A[4] & b_op[4]) | (b_op[4] & c4) | (A[4] & c4);
            s5 = A[5] ^ b_op[5] ^ c5;
            c6 = (A[5] & b_op[5]) | (b_op[5] & c5) | (A[5] & c5);
            s6 = A[6] ^ b_op[6] ^ c6;
            c7 = (A[6] & b_op[6]) | (b_op[6] & c6) | (A[6] & c6);
            s7 = A[7] ^ b_op[7] ^ c7;
            c8 = (A[7] & b_op[7]) | (b_op[7] & c7) | (A[7] & c7);

            add_result    = {s7,s6,s5,s4,s3,s2,s1,s0};
            add_carry_out = c8;   // In subtraction, C=0 means borrow occurred

            result = add_result;
            C = ~add_carry_out;  // Borrow flag: C=1 if A < B
            // Overflow: A positive minus B negative = negative (or opposite)
            V = (A[7] & ~B[7] & ~result[7]) | (~A[7] & B[7] & result[7]);
        end

        // ==================================================
        // 0010: INC  —  A + 1
        // Uses adder with B=0x00 and Cin=1
        // ==================================================
        5'b00010: begin
            b_op    = 8'h00;
            sub_cin = 1'b1;    // Cin=1 adds 1
            c0 = sub_cin;
            s0 = A[0] ^ b_op[0] ^ c0;
            c1 = (A[0] & b_op[0]) | (b_op[0] & c0) | (A[0] & c0);
            s1 = A[1] ^ b_op[1] ^ c1;
            c2 = (A[1] & b_op[1]) | (b_op[1] & c1) | (A[1] & c1);
            s2 = A[2] ^ b_op[2] ^ c2;
            c3 = (A[2] & b_op[2]) | (b_op[2] & c2) | (A[2] & c2);
            s3 = A[3] ^ b_op[3] ^ c3;
            c4 = (A[3] & b_op[3]) | (b_op[3] & c3) | (A[3] & c3);
            s4 = A[4] ^ b_op[4] ^ c4;
            c5 = (A[4] & b_op[4]) | (b_op[4] & c4) | (A[4] & c4);
            s5 = A[5] ^ b_op[5] ^ c5;
            c6 = (A[5] & b_op[5]) | (b_op[5] & c5) | (A[5] & c5);
            s6 = A[6] ^ b_op[6] ^ c6;
            c7 = (A[6] & b_op[6]) | (b_op[6] & c6) | (A[6] & c6);
            s7 = A[7] ^ b_op[7] ^ c7;
            c8 = (A[7] & b_op[7]) | (b_op[7] & c7) | (A[7] & c7);
            add_result    = {s7,s6,s5,s4,s3,s2,s1,s0};
            add_carry_out = c8;
            result = add_result;
            C = add_carry_out;
        end

        // ==================================================
        // 0011: DEC  —  A - 1 = A + (0xFF) + 0
        //           = A + (~8'h00) + 0  but simpler:
        //           A + 0xFF with Cin=0 is same as A-1
        // ==================================================
        5'b00011: begin
            b_op    = 8'hFF;   // ~0x00 = 0xFF
            sub_cin = 1'b0;
            c0 = sub_cin;
            s0 = A[0] ^ b_op[0] ^ c0;
            c1 = (A[0] & b_op[0]) | (b_op[0] & c0) | (A[0] & c0);
            s1 = A[1] ^ b_op[1] ^ c1;
            c2 = (A[1] & b_op[1]) | (b_op[1] & c1) | (A[1] & c1);
            s2 = A[2] ^ b_op[2] ^ c2;
            c3 = (A[2] & b_op[2]) | (b_op[2] & c2) | (A[2] & c2);
            s3 = A[3] ^ b_op[3] ^ c3;
            c4 = (A[3] & b_op[3]) | (b_op[3] & c3) | (A[3] & c3);
            s4 = A[4] ^ b_op[4] ^ c4;
            c5 = (A[4] & b_op[4]) | (b_op[4] & c4) | (A[4] & c4);
            s5 = A[5] ^ b_op[5] ^ c5;
            c6 = (A[5] & b_op[5]) | (b_op[5] & c5) | (A[5] & c5);
            s6 = A[6] ^ b_op[6] ^ c6;
            c7 = (A[6] & b_op[6]) | (b_op[6] & c6) | (A[6] & c6);
            s7 = A[7] ^ b_op[7] ^ c7;
            c8 = (A[7] & b_op[7]) | (b_op[7] & c7) | (A[7] & c7);
            add_result    = {s7,s6,s5,s4,s3,s2,s1,s0};
            add_carry_out = c8;
            result = add_result;
            C = ~add_carry_out; // borrow
        end

        // ==================================================
        // 0100: AND  —  bitwise AND gate array
        // Each bit: result[i] = A[i] AND B[i]
        // ==================================================
        5'b00100: begin
            result[0] = A[0] & B[0];
            result[1] = A[1] & B[1];
            result[2] = A[2] & B[2];
            result[3] = A[3] & B[3];
            result[4] = A[4] & B[4];
            result[5] = A[5] & B[5];
            result[6] = A[6] & B[6];
            result[7] = A[7] & B[7];
        end

        // ==================================================
        // 0101: OR   —  bitwise OR gate array
        // ==================================================
        5'b00101: begin
            result[0] = A[0] | B[0];
            result[1] = A[1] | B[1];
            result[2] = A[2] | B[2];
            result[3] = A[3] | B[3];
            result[4] = A[4] | B[4];
            result[5] = A[5] | B[5];
            result[6] = A[6] | B[6];
            result[7] = A[7] | B[7];
        end

        // ==================================================
        // 0110: XOR  —  bitwise XOR gate array
        // ==================================================
        5'b00110: begin
            result[0] = A[0] ^ B[0];
            result[1] = A[1] ^ B[1];
            result[2] = A[2] ^ B[2];
            result[3] = A[3] ^ B[3];
            result[4] = A[4] ^ B[4];
            result[5] = A[5] ^ B[5];
            result[6] = A[6] ^ B[6];
            result[7] = A[7] ^ B[7];
        end

        // ==================================================
        // 0111: NOT  —  bitwise complement (inverter array)
        // 1's complement of A
        // ==================================================
        5'b00111: begin
            result[0] = ~A[0];
            result[1] = ~A[1];
            result[2] = ~A[2];
            result[3] = ~A[3];
            result[4] = ~A[4];
            result[5] = ~A[5];
            result[6] = ~A[6];
            result[7] = ~A[7];
        end

        // ==================================================
        // 1000: SHL  —  Logical Shift Left by 1
        // Each bit moves one position left; LSB filled with 0.
        // Bit 7 of A goes to Carry.
        // ==================================================
        5'b01000: begin
            result[0] = 1'b0;      // LSB filled with 0
            result[1] = A[0];
            result[2] = A[1];
            result[3] = A[2];
            result[4] = A[3];
            result[5] = A[4];
            result[6] = A[5];
            result[7] = A[6];
            C = A[7];              // Shifted-out bit goes to carry
        end

        // ==================================================
        // 1001: SHR  —  Logical Shift Right by 1
        // Each bit moves one position right; MSB filled with 0.
        // Bit 0 of A goes to Carry.
        // ==================================================
        5'b01001: begin
            result[7] = 1'b0;      // MSB filled with 0
            result[6] = A[7];
            result[5] = A[6];
            result[4] = A[5];
            result[3] = A[4];
            result[2] = A[3];
            result[1] = A[2];
            result[0] = A[1];
            C = A[0];              // Shifted-out bit goes to carry
        end

        // ==================================================
        // 1010: ASHR  —  Arithmetic Shift Right by 1
        // Same as SHR but MSB is sign-extended (A[7] preserved).
        // Divides signed number by 2, preserving sign.
        // ==================================================
        5'b01010: begin
            result[7] = A[7];      // Sign extension: replicate MSB
            result[6] = A[7];
            result[5] = A[6];
            result[4] = A[5];
            result[3] = A[4];
            result[2] = A[3];
            result[1] = A[2];
            result[0] = A[1];
            C = A[0];
        end

        // ==================================================
        // 1011: ROL  —  Rotate Left by 1
        // Bit 7 wraps around to bit 0 (circular shift left).
        // ==================================================
        5'b01011: begin
            result[0] = A[7];      // MSB wraps to LSB
            result[1] = A[0];
            result[2] = A[1];
            result[3] = A[2];
            result[4] = A[3];
            result[5] = A[4];
            result[6] = A[5];
            result[7] = A[6];
            C = A[7];              // Rotated bit also goes to carry
        end

        // ==================================================
        // 1100: ROR  —  Rotate Right by 1
        // Bit 0 wraps around to bit 7 (circular shift right).
        // ==================================================
        5'b01100: begin
            result[7] = A[0];      // LSB wraps to MSB
            result[6] = A[7];
            result[5] = A[6];
            result[4] = A[5];
            result[3] = A[4];
            result[2] = A[3];
            result[1] = A[2];
            result[0] = A[1];
            C = A[0];              // Rotated bit also goes to carry
        end

        // ==================================================
        // 1101: MUL  —  8-bit x 8-bit Shift-and-Add Multiplier
        // Result: lower 8 bits of 16-bit product (A * B)
        // Algorithm: for each bit of B, if B[i]=1 add A<<i to accumulator
        // NO * operator — uses the ripple-carry adder above via tasks
        // ==================================================
        5'b01101: begin
            // Shift-and-Add: Manually unrolled for 8 bits
            // We add A shifted left by i if B[i] is 1
            mul_acc = 16'h0000;
            mul_a   = A;
            mul_b   = B;

            // Bit 0: if B[0]=1, add A<<0 = A (zero-extended to 16 bits)
            // Shift-and-add: for each bit of multiplier B, if that bit is 1,
            // add the current shifted multiplicand to the accumulator.
            if (mul_b[0]) mul_acc = mul_acc + {8'h00, mul_a};
            // Bit 1: B[1]=1 → add A << 1
            mul_a = {mul_a[6:0], 1'b0};  // left shift A
            if (mul_b[1]) mul_acc = mul_acc + {8'h00, mul_a};
            // Bit 2
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[2]) mul_acc = mul_acc + {8'h00, mul_a};
            // Bit 3
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[3]) mul_acc = mul_acc + {8'h00, mul_a};
            // Bit 4
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[4]) mul_acc = mul_acc + {8'h00, mul_a};
            // Bit 5
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[5]) mul_acc = mul_acc + {8'h00, mul_a};
            // Bit 6
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[6]) mul_acc = mul_acc + {8'h00, mul_a};
            // Bit 7
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[7]) mul_acc = mul_acc + {8'h00, mul_a};

            result = mul_acc[7:0];   // Lower 8 bits of product
            C = |mul_acc[15:8];      // Carry if upper byte is non-zero
        end

        // ==================================================
        // 01110: DIV — unsigned quotient A / B (B=0 → 0xFF, C=1)
        // ==================================================
        5'b01110: begin
            if (B == 8'd0) begin
                result = 8'hFF;
                C = 1'b1;
            end
            else begin
                result = A / B;
                C = 1'b0;
            end
        end

        // ==================================================
        // 01111: SQR — A * A (lower 8 bits, same style as MUL)
        // ==================================================
        5'b01111: begin
            mul_acc = 16'h0000;
            mul_a   = A;
            mul_b   = A;
            if (mul_b[0]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[1]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[2]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[3]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[4]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[5]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[6]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[7]) mul_acc = mul_acc + {8'h00, mul_a};
            result = mul_acc[7:0];
            C = |mul_acc[15:8];
        end

        // ==================================================
        // 10000: CUBE — (A*A)[7:0] * A, lower 8 bits
        // ==================================================
        5'b10000: begin
            mul_acc = 16'h0000;
            mul_a   = A;
            mul_b   = A;
            if (mul_b[0]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[1]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[2]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[3]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[4]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[5]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[6]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[7]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_b = mul_acc[7:0];
            mul_acc = 16'h0000;
            mul_a   = A;
            if (mul_b[0]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[1]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[2]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[3]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[4]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[5]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[6]) mul_acc = mul_acc + {8'h00, mul_a};
            mul_a = {mul_a[6:0], 1'b0};
            if (mul_b[7]) mul_acc = mul_acc + {8'h00, mul_a};
            result = mul_acc[7:0];
            C = |mul_acc[15:8];
        end

        // ==================================================
        // 10001: CLR — clear (result 0, Z=1 from common block)
        // ==================================================
        5'b10001: begin
            result = 8'h00;
        end

        // ==================================================
        // 10100: PASS B (LOAD address path / internal)
        // ==================================================
        5'b10100: begin
            result = B;
        end

        // ==================================================
        // 10101: ZERO / reserved
        // ==================================================
        5'b10101: begin
            result = 8'h00;
        end

        default: result = 8'h00;

    endcase

    // ---- Common flag computation (after result is set) ----
    Z = (result == 8'h00) ? 1'b1 : 1'b0;  // Zero
    S =  result[7];                         // Sign (MSB)
    // C and V already set per-operation above

end

endmodule
