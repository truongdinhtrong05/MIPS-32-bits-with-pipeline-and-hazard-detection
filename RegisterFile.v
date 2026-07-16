module RegisterFile (
    input clk,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] writereg,
    input [31:0] writedata,
    input regwrite,
    output reg [31:0] readdata1,
    output reg [31:0] readdata2
);

reg [31:0] register [31:0];

always @(posedge clk) begin
    if (regwrite && writereg != 5'd0) begin
        register[writereg] <= writedata;
    end
end

always @(*) begin
    register[0] = 32'd0; // Đảm bảo thanh ghi $0 luôn bằng 0

    if (regwrite && (writereg == rs1) && (writereg != 5'd0)) begin
        readdata1 = writedata;
    end else begin
        readdata1 = register[rs1];
    end

    if (regwrite && (writereg == rs2) && (writereg != 5'd0)) begin
        readdata2 = writedata;
    end else begin
        readdata2 = register[rs2];
    end
end

endmodule