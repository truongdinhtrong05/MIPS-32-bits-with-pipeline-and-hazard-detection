module AluControl(
    input [5:0] funct,
    input [2:0] AluOp,
    output reg [5:0] aluctrl
);

always @(*) begin
    case (AluOp)
        3'd0: aluctrl = funct; // R-type
        3'd1: aluctrl = 6'h20; // cộng
        3'd2: aluctrl = 6'h22; // trừ
        3'd3: aluctrl = 6'h24; // and
        3'd4: aluctrl = 6'h25; // or
        default: aluctrl = 6'h00;
    endcase
end
endmodule
