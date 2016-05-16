module rvbridge_fifo_max(
	clk,rst_n,
	usedw,maxusedw
);

parameter			USEDW_WIDTH = 15;

input								clk,rst_n;
input		[USEDW_WIDTH-1:0]	usedw;
output	[USEDW_WIDTH-1:0]	maxusedw;

reg		[USEDW_WIDTH-1:0]	maxusedw_reg;

assign maxusedw = maxusedw_reg;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		maxusedw_reg <= usedw;
	else
		maxusedw_reg <= (maxusedw_reg > usedw) ? maxusedw_reg : usedw;
end

endmodule
