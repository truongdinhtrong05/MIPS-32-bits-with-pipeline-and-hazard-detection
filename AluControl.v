module AluControl (
    input [5:0] funct,
    input [2:0] AluOp,
    output reg [5:0] aluctrl
);

always @(*) begin
    case (AluOp)
        // 1. Nhóm R-Type (add, sub, and, or, nor, xor, slt, mult, div, mfhi, mflo)
        // Main Control sẽ gửi AluOp = 0. ALU Control lấy trực tiếp 6 bit funct của lệnh đưa cho ALU.
        3'd0: aluctrl = funct;       
        
        // 2. Nhóm tính tổng (lw, sw, addi, li)
        // Cần ALU tính địa chỉ (Base + Offset) hoặc cộng hằng số.
        // Ép ALU làm phép CỘNG (mã funct của 'add' trên Green Card là 0x20 / 6'h20)
        3'd1: aluctrl = 6'h20;       

        // 3. Nhóm rẽ nhánh và trừ hằng số (beq, bne, subi)
        // Cần ALU làm phép trừ để so sánh (A - B == 0) hoặc trừ số thực tế.
        // Ép ALU làm phép TRỪ (mã funct của 'sub' là 0x22 / 6'h22)
        3'd2: aluctrl = 6'h22;       

        // 4. Nhóm logic AND với hằng số (andi)
        // Ép ALU làm phép AND (mã funct của 'and' là 0x24 / 6'h24)
        3'd3: aluctrl = 6'h24;       

        // 5. Nhóm logic OR với hằng số (ori)
        // Ép ALU làm phép OR (mã funct của 'or' là 0x25 / 6'h25)
        3'd4: aluctrl = 6'h25;       

        // 6. Trường hợp an toàn (j - jump)
        // Lệnh Jump không dùng ALU, gán một giá trị mặc định để tránh sinh ra chốt (latch).
        default: aluctrl = 6'h00;    
    endcase
end

endmodule