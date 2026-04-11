// ============================================================
// data_memory.v
// 256 x 8-bit Data RAM
// Synchronous write, Synchronous read
// Pre-loaded with test data
// ============================================================
`timescale 1ns/1ps

module data_memory(
    input        clk,
    input        mem_write,
    input        mem_read,
    input  [7:0] addr,
    input  [7:0] write_data,
    output reg [7:0] read_data
);

    reg [7:0] memory [0:255];
    initial read_data = 8'h00;

    // Pre-load test data
    initial begin
        memory[8'h00] = 8'd5;    // addr 0x00 = 5
        memory[8'h01] = 8'd10;   // addr 0x01 = 10
        memory[8'h02] = 8'd3;    // addr 0x02 = 3
        memory[8'h03] = 8'd7;    // addr 0x03 = 7
        memory[8'h10] = 8'hAA;   // addr 0x10 = 0xAA (test pattern)
        memory[8'h11] = 8'h55;   // addr 0x11 = 0x55 (test pattern)
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write)
            memory[addr] <= write_data;
    end

    // Synchronous read — hold last read value when mem_read=0 (WB needs stable data)
    always @(posedge clk) begin
        if (mem_read)
            read_data <= memory[addr];
    end

endmodule
