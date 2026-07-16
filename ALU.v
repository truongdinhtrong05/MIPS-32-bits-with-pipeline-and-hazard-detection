module ALU(a,b,aluctrl,result,isz);
input [31:0] a;
input [31:0] b;
input [5:0] aluctrl;
output [31:0] result;
output isz;

assign result = 	(aluctrl==6'h20)? $signed(a)+$signed(b):
						(aluctrl==6'h21)? $unsigned(a)+$unsigned(b):
						(aluctrl==6'h22)? $signed(a)-$signed(b):
						(aluctrl==6'h23)? $unsigned(a)-$unsigned(b):
						(aluctrl==6'h24)? a & b:
						(aluctrl==6'h25)? a | b:
						(aluctrl==6'h26)? a ^ b:
						(aluctrl==6'h27)? ~(a|b):
						(aluctrl==6'h2a)? (($signed(a)<$signed(b))?1:0):32'dZ;
assign isz = (result==32'd0)? 1:0;
endmodule
