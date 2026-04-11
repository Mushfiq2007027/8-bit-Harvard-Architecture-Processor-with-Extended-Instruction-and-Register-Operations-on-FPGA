// ============================================================
// register_file.v
// 4 x 8-bit Register File (R0 - R3)
// Synchronous write, Asynchronous read
// ============================================================

`timescale 1ns/1ps

module register_file(
    input        clk,
    input        reset,
    input        write_enable,
    input  [1:0] read_addr1,   // Source register address (Rs)
    input  [1:0] read_addr2,   // Destination register address (Rd) for read
    input  [1:0] write_addr,   // Register to write result into
    input  [7:0] write_data,   // Data to write

    input        ext_write,    // BTND: load SW[15:8] into ext_waddr (has priority)
    input  [1:0] ext_waddr,
    input  [7:0] ext_wdata,

    output [7:0] read_data1,   // Rs value
    output [7:0] read_data2    // Rd value (also ALU A operand)
);

    reg [7:0] registers [0:3];  // R0, R1, R2, R3

    // Synchronous write with reset
    always @(posedge clk) begin
        if (reset) begin
            registers[0] <= 8'h00;  // R0 = 0
            registers[1] <= 8'h0A;  // R1 = 10 (decimal) - test value
            registers[2] <= 8'h03;  // R2 = 3            - test value
            registers[3] <= 8'h00;  // R3 = 0
        end
        else if (ext_write) begin
            registers[ext_waddr] <= ext_wdata;
        end
        else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end

    // Asynchronous read (combinational)
    assign read_data1 = registers[read_addr1];  // Rs
    assign read_data2 = registers[read_addr2];  // Rd

endmodule
