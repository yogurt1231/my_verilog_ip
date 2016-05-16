module rvbridge_make_se(
	clk,rst_n,
	raw_data,raw_fs,
	st_data,st_valid,st_startofpacket,st_endofpacket
);

parameter						DATA_WIDTH = 8;

input								clk,rst_n;
input		[DATA_WIDTH-1:0]	raw_data;
input								raw_fs;
output	[DATA_WIDTH-1:0]	st_data;
output							st_valid,st_startofpacket,st_endofpacket;

reg		[DATA_WIDTH-1:0]	raw_data_reg;
reg								raw_fs_reg;
reg								st_startofpacket_reg;

assign st_data = raw_data_reg;
assign st_valid = raw_fs_reg;
assign st_startofpacket = st_startofpacket_reg;
assign st_endofpacket = {raw_fs_reg,raw_fs}==2'b10;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		{raw_data_reg,raw_fs_reg} <= 'd0;
	else
		{raw_data_reg,raw_fs_reg} <= {raw_data,raw_fs};
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		st_startofpacket_reg <= 1'b0;
	else if({raw_fs_reg,raw_fs}==2'b01)
		st_startofpacket_reg <= 1'b1;
	else
		st_startofpacket_reg <= 1'b0;
end

endmodule
