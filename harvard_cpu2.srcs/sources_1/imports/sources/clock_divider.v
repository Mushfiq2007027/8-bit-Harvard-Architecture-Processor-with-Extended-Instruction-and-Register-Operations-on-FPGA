// ============================================================
// clock_divider.v
// Generates a slow clock from the 100 MHz Basys3 system clock.
// Used for slow-motion execution visualization on FPGA.
//
// Output frequencies (approximate, 100 MHz base):
//   SLOW_CLK: ~1.5 Hz  (every 2^26 cycles)  — visible on LEDs
//   MED_CLK:  ~6 Hz    (every 2^24 cycles)  — moderate speed
//   FAST_CLK: ~24 Hz   (every 2^22 cycles)  — fast but watchable
//
// The top_module selects which clock to use based on SW[15:14].
// ============================================================

module clock_divider(
    input  clk,         // 100 MHz system clock
    input  reset,
    output slow_clk,    // ~1.5 Hz
    output med_clk,     // ~6 Hz
    output fast_clk     // ~24 Hz
);

    reg [26:0] counter;

    always @(posedge clk) begin
        if (reset)
            counter <= 27'd0;
        else
            counter <= counter + 1'b1;
    end

    assign slow_clk = counter[26];  // bit 26 toggles every 2^26 cycles
    assign med_clk  = counter[24];
    assign fast_clk = counter[22];

endmodule
