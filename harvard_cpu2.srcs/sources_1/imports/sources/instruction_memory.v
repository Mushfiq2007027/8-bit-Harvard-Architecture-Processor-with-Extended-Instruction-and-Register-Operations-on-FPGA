// ============================================================
// instruction_memory.v
// 256 x 8-bit ROM for storing program machine codes
// ============================================================
`timescale 1ns/1ps

module instruction_memory(
    input  [7:0] addr,   // Program Counter address
    output [7:0] instr   // 8-bit instruction output
);

    reg [7:0] mem [0:255];

    // Asynchronous read - instruction is available immediately
    assign instr = mem[addr];

    initial begin
        // Relative to this file (sources/): memory lives in vivado_src/memory_files/
        $readmemh("E:/harvard_cpu2/harvard_cpu2.srcs/sources_1/imports/memory_files/program.mem", mem);
    end

endmodule
