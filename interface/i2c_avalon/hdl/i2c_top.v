module i2c_top(
	clk,rst_n,
	
	av_address,av_write,av_read,
	av_writedata,av_readdata,
	av_readdatavalid,av_waitrequest,
	
	i2c_scl,i2c_sda
);

parameter			DIV_CNT = 50;

input					clk,rst_n;

input		[1:0]		av_address;
input					av_write,av_read;
input		[31:0]	av_writedata;
output	[31:0]	av_readdata;
output				av_readdatavalid,av_waitrequest;
 
output				i2c_scl;
inout					i2c_sda;

wire					i2c_pclk;

i2c_clk_div #(
	.DIV_CNT(DIV_CNT))
u1(
	.clk(clk),
	.rst_n(rst_n),
	.pclk(i2c_pclk)
);

i2c_interface u2(
	.clk(clk),
	.rst_n(rst_n),
	.i2c_pclk(i2c_pclk),
	
	.av_address(av_address),
	.av_write(av_write),
	.av_read(av_read),
	.av_writedata(av_writedata),
	.av_readdata(av_readdata),
	.av_readdatavalid(av_readdatavalid),
	.av_waitrequest(av_waitrequest),
	
	.i2c_scl(i2c_scl),
	.i2c_sda(i2c_sda)
);

endmodule
