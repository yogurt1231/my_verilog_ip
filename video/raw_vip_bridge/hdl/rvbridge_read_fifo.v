module rvbridge_read_fifo(
	clk,rst_n,
	fifo_empty,vst_ready,
	fifo_rdreq,vst_valid,
	fifo_aclr
);

input		clk,rst_n;
input		fifo_empty,vst_ready;
output	fifo_rdreq,vst_valid;
output	fifo_aclr;

reg		vst_valid_reg;

assign	fifo_rdreq = (~fifo_empty) & vst_ready;
assign	vst_valid = vst_valid_reg;
assign	fifo_aclr = ~rst_n;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		vst_valid_reg <= 1'b0;
	else
		vst_valid_reg <= fifo_rdreq;
end

endmodule
