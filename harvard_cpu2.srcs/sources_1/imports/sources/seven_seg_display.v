// ============================================================
// seven_seg_display.v
// 4-digit 7-segment display controller for Basys3
// Multiplexes 4 digits at ~1 kHz refresh rate
//
// Display layout (per project spec):
//   Digit 0 (rightmost) : PC low nibble
//   Digit 1             : PC high nibble
//   Digit 2             : ALU / result low nibble
//   Digit 3 (leftmost)  : ALU / result high nibble
// ============================================================

module seven_seg_display(
    input        clk,
    input        reset,
    input  [7:0] pc_val,       // Program Counter
    input  [7:0] alu_result,   // ALU result to display

    output reg [3:0] an,       // Anode: active LOW (one digit at a time)
    output reg [6:0] seg       // Cathode segments: active LOW
);

    // Internal counter for multiplexing
    reg [17:0] refresh_counter;
    reg [1:0]  digit_sel;

    always @(posedge clk) begin
        if (reset)
            refresh_counter <= 18'd0;
        else
            refresh_counter <= refresh_counter + 1'b1;
    end

    always @(*) begin
        digit_sel = refresh_counter[17:16];  // ~763 Hz refresh
    end

    // Digit multiplexer
    reg [3:0] nibble;

    always @(*) begin
        case (digit_sel)
            2'b00: begin an = 4'b1110; nibble = pc_val[3:0];         end
            2'b01: begin an = 4'b1101; nibble = pc_val[7:4];         end
            2'b10: begin an = 4'b1011; nibble = alu_result[3:0];     end
            2'b11: begin an = 4'b0111; nibble = alu_result[7:4];     end
        endcase
    end

    // Hex to 7-segment decoder (common anode: 0 = segment ON)
    // Segments: seg[6:0] = {gfedcba}
    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000;  // 0
            4'h1: seg = 7'b1111001;  // 1
            4'h2: seg = 7'b0100100;  // 2
            4'h3: seg = 7'b0110000;  // 3
            4'h4: seg = 7'b0011001;  // 4
            4'h5: seg = 7'b0010010;  // 5
            4'h6: seg = 7'b0000010;  // 6
            4'h7: seg = 7'b1111000;  // 7
            4'h8: seg = 7'b0000000;  // 8
            4'h9: seg = 7'b0010000;  // 9
            4'hA: seg = 7'b0001000;  // A
            4'hB: seg = 7'b0000011;  // b
            4'hC: seg = 7'b1000110;  // C
            4'hD: seg = 7'b0100001;  // d
            4'hE: seg = 7'b0000110;  // E
            4'hF: seg = 7'b0001110;  // F
            default: seg = 7'b1111111;
        endcase
    end

endmodule
