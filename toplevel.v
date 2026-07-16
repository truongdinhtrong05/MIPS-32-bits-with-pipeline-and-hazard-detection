module toplevel(
    input clk,
    input pcreset,
	 output [31:0]instview,
	 output [31:0]aluresult
);
assign instview = inst;

// --- IF STAGE ---
reg [31:0] pc;
wire [31:0] pc_4;
wire [31:0] pc_next;
wire flush;

assign pc_4 = pc + 4;
assign pc_next = (flush) ? ex_mem_branchpc : (jump) ? jump_address : pc_4;

always @(posedge clk or negedge pcreset) begin
    if(!pcreset)
        pc <= 32'd0;
    else 
        pc <= pc_next;
end

wire [31:0] inst;
IMEM imem1 (
    .readadr(pc),
    .inst(inst)
);

// --- IF_ID REGISTER ---
reg [31:0] if_id_inst;
reg [31:0] if_id_pc;

always @(posedge clk or negedge pcreset) begin
    if(!pcreset) begin
        if_id_inst <= 0;
        if_id_pc <= 0;
    end else if (flush || jump) begin
        if_id_inst <= 0;
        if_id_pc <= 0;
    end else begin
        if_id_inst <= inst;
        if_id_pc <= pc_4;
    end
end

// --- ID STAGE ---
wire regdst, branch, memread, memtoreg, memwrite, alusrc, regwrite, bne, jump;
wire [2:0] aluop;

Controller controller1 (
    .inst(if_id_inst[31:26]),
    .regdst(regdst),
    .branch(branch),
    .memread(memread),
    .memtoreg(memtoreg),
    .aluop(aluop),
    .memwrite(memwrite),
    .alusrc(alusrc),
    .regwrite(regwrite),
    .bne(bne),
	 .jump(jump)
);
wire [31:0] jump_address;
assign jump_address = {if_id_pc[31:28], if_id_inst[25:0], 2'b00};

wire [31:0] readdata1, readdata2;
wire [4:0] writereg;
assign writereg = (regdst) ? if_id_inst[15:11] : if_id_inst[20:16];

wire [31:0] mem_wb_data; 
wire [4:0] mem_wb_rd;
wire mem_wb_regwrite;

RegisterFile rf1 (
    .clk(clk),
    .rs1(if_id_inst[25:21]),
    .rs2(if_id_inst[20:16]),
    .regwrite(mem_wb_regwrite),
    .writereg(mem_wb_rd),
    .readdata1(readdata1),
    .readdata2(readdata2),
    .writedata(mem_wb_data)
);

wire [31:0] signex;
SignExtend sign1(
    .a(if_id_inst[15:0]),
    .b(signex)
);

// --- ID_EX REGISTER ---
reg id_ex_branch, id_ex_memread, id_ex_memtoreg, id_ex_memwrite;
reg id_ex_alusrc, id_ex_regwrite, id_ex_bne;
reg [2:0] id_ex_aluop;
reg [4:0] id_ex_rs1, id_ex_rs2, id_ex_rd;
reg [31:0] id_ex_signex, id_ex_data1, id_ex_data2, id_ex_pc;

always @(posedge clk or negedge pcreset) begin
    if(!pcreset) begin
        id_ex_branch <= 0;   
		  id_ex_memread <= 0;
        id_ex_memtoreg <= 0; 
		  id_ex_aluop <= 0;
        id_ex_memwrite <= 0; 
		  id_ex_alusrc <= 0;
        id_ex_regwrite <= 0; 
		  id_ex_bne <= 0;
        id_ex_rs1 <= 0;      
		  id_ex_rs2 <= 0;
        id_ex_rd <= 0;       
		  id_ex_signex <= 0;
        id_ex_data1 <= 0;    
		  id_ex_data2 <= 0;
        id_ex_pc <= 0;
    end else if (flush) begin
        id_ex_branch <= 0;   
		  id_ex_memread <= 0;
        id_ex_memtoreg <= 0; 
		  id_ex_aluop <= 0;
        id_ex_memwrite <= 0; 
		  id_ex_alusrc <= 0;
        id_ex_regwrite <= 0; 
		  id_ex_bne <= 0;
        id_ex_rs1 <= 0;      
		  id_ex_rs2 <= 0;
        id_ex_rd <= 0;       
		  id_ex_signex <= 0;
        id_ex_data1 <= 0;    
		  id_ex_data2 <= 0;
        id_ex_pc <= 0;
    end else begin      
        id_ex_branch <= branch;       
		  id_ex_memread <= memread;
        id_ex_memtoreg <= memtoreg;   
		  id_ex_aluop <= aluop;
        id_ex_memwrite <= memwrite;   
		  id_ex_alusrc <= alusrc;
        id_ex_regwrite <= regwrite;   
		  id_ex_bne <= bne;
        id_ex_rs1 <= if_id_inst[25:21];
        id_ex_rs2 <= if_id_inst[20:16];
        id_ex_rd <= writereg;
        id_ex_signex <= signex;
        id_ex_data1 <= readdata1;
        id_ex_data2 <= readdata2;
        id_ex_pc <= if_id_pc;
    end
end

// --- EX STAGE ---
wire [1:0] sela, selb;
reg [31:0] a, b;
wire [31:0] balu, result;
wire is0;
wire [4:0] ex_mem_rd;
wire ex_mem_regwrite;
reg [31:0] ex_mem_result;

forwarding forward1(
    .id_ex_rs1(id_ex_rs1),
    .id_ex_rs2(id_ex_rs2),
    .ex_mem_rd(ex_mem_rd),
    .mem_wb_rd(mem_wb_rd),
    .ex_mem_wb(ex_mem_regwrite),
    .mem_wb_wb(mem_wb_regwrite),
    .sela(sela),
    .selb(selb)
);

always @(*) begin
    case(sela)
        2'b00: a = id_ex_data1;
        2'b01: a = ex_mem_result;
        2'b10: a = mem_wb_data;
        default: a = id_ex_data1;
    endcase
    case(selb)
        2'b00: b = id_ex_data2;
        2'b01: b = ex_mem_result;
        2'b10: b = mem_wb_data;
        default: b = id_ex_data2;
    endcase
end

assign balu = (id_ex_alusrc) ? id_ex_signex : b;

wire [5:0] aluctrl;
AluControl aluctrl1(
    .AluOp(id_ex_aluop),
    .funct(id_ex_signex[5:0]),
    .aluctrl(aluctrl)
);

ALU alu1(
    .a(a),
    .b(balu),
    .aluctrl(aluctrl),
    .result(result),
    .isz(is0)
);
assign aluresult = result;

wire [31:0] branchpc;
assign branchpc = {id_ex_signex[29:0], 2'b00} + id_ex_pc;

// --- EX_MEM REGISTER ---
reg ex_mem_is0, ex_mem_branch, ex_mem_memwrite;
reg ex_mem_memread, ex_mem_memtoreg, ex_mem_bne;
reg [31:0] ex_mem_writedata, ex_mem_pc, ex_mem_branchpc;
reg [4:0] ex_mem_rd_reg;
reg ex_mem_regwrite_reg;

assign ex_mem_rd = ex_mem_rd_reg;
assign ex_mem_regwrite = ex_mem_regwrite_reg;

always @(posedge clk or negedge pcreset) begin
    if(!pcreset) begin
        ex_mem_result <= 0;       
		  ex_mem_is0 <= 0;
        ex_mem_writedata <= 0;    
		  ex_mem_rd_reg <= 0;
        ex_mem_branch <= 0;       
		  ex_mem_memwrite <= 0;
        ex_mem_memread <= 0;      
		  ex_mem_regwrite_reg <= 0;
        ex_mem_memtoreg <= 0;     
		  ex_mem_pc <= 0;
        ex_mem_branchpc <= 0;     
		  ex_mem_bne <= 0;
    end else if (flush) begin      
		  ex_mem_result <= 0;       
        ex_mem_writedata <= 0;    
		  ex_mem_rd_reg <= 0;       
		  ex_mem_memwrite <= 0;
        ex_mem_memread <= 0;      
		  ex_mem_regwrite_reg <= 0;
        ex_mem_memtoreg <= 0;     
		  ex_mem_pc <= 0;     
    end else begin
        ex_mem_is0 <= is0;
        ex_mem_result <= result;
        ex_mem_writedata <= b;
        ex_mem_rd_reg <= id_ex_rd;
        ex_mem_branch <= id_ex_branch;
        ex_mem_memwrite <= id_ex_memwrite;
        ex_mem_memread <= id_ex_memread;
        ex_mem_regwrite_reg <= id_ex_regwrite;
        ex_mem_memtoreg <= id_ex_memtoreg;
        ex_mem_pc <= id_ex_pc;
        ex_mem_branchpc <= branchpc;
        ex_mem_bne <= id_ex_bne;
    end
end

// --- MEM STAGE ---
wire [31:0] memdata;
DMEM mem1(
    .clk(clk),
    .address(ex_mem_result),
    .writedata(ex_mem_writedata),
    .memwrite(ex_mem_memwrite),
    .memread(ex_mem_memread),
    .readdata(memdata)
);

assign flush = (ex_mem_branch && ex_mem_is0) || (ex_mem_bne && !ex_mem_is0);

// --- MEM_WB REGISTER ---
reg [31:0] mem_wb_alu_result;
reg [31:0] mem_wb_mem_data;
reg mem_wb_memtoreg;
reg [4:0] mem_wb_rd_reg;
reg mem_wb_regwrite_reg;

assign mem_wb_rd = mem_wb_rd_reg;
assign mem_wb_regwrite = mem_wb_regwrite_reg;

always @(posedge clk or negedge pcreset) begin
    if(!pcreset) begin
        mem_wb_alu_result <= 0;
        mem_wb_mem_data <= 0;
        mem_wb_memtoreg <= 0;
        mem_wb_regwrite_reg <= 0;
        mem_wb_rd_reg <= 0;
    end else begin
        mem_wb_alu_result <= ex_mem_result;
        mem_wb_mem_data <= memdata;
        mem_wb_memtoreg <= ex_mem_memtoreg;
        mem_wb_regwrite_reg <= ex_mem_regwrite_reg;
        mem_wb_rd_reg <= ex_mem_rd_reg;
    end
end

// --- WB STAGE ---
assign mem_wb_data = (mem_wb_memtoreg) ? mem_wb_mem_data : mem_wb_alu_result;

endmodule
