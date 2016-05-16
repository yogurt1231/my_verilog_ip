module i2c_clk_div(
	clk,rst_n,
	pclk
);

parameter		DIV_CNT = 20_000_000/100_000/4;

input				clk,rst_n;
output			pclk;

reg	[15:0]	cnt;
wire	[15:0]	cnt_add_1;

assign cnt_add_1 = cnt + 16'd1;
assign pclk = (cnt_add_1 == DIV_CNT);

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt <= 16'd0;
	else
		cnt <= (cnt_add_1 == DIV_CNT) ? 16'd0 : cnt_add_1;
end

endmodule
