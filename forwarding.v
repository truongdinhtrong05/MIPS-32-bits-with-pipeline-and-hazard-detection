module forwarding(
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    input [4:0] ex_mem_rd,
    input [4:0] mem_wb_rd,
    input ex_mem_wb,
    input mem_wb_wb,
    output reg [1:0] sela,
    output reg [1:0] selb
);

// 0: ID/EX, 1: EX/MEM, 2: MEM/WB
always @(*) begin
    if (id_ex_rs1==ex_mem_rd && ex_mem_wb && ex_mem_rd!=0)
        sela = 1;
    else if (id_ex_rs1==mem_wb_rd && mem_wb_wb && mem_wb_rd!=0)
        sela = 2;
    else
        sela = 0;

    if (id_ex_rs2==ex_mem_rd && ex_mem_wb && ex_mem_rd!=0)
        selb = 1;
    else if (id_ex_rs2==mem_wb_rd && mem_wb_wb && mem_wb_rd!=0)
        selb = 2;
    else
        selb = 0;
end
endmodule
