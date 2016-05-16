module GB_stat(
	clk,rst_n,
	
	din_data,din_valid,
	din_startofpacket,
	aft_data,aft_valid,
	aft_endofpacket,
	
	ram_read_addr,ram_read_q,
	ram_write_addr,ram_write,
	
	stat_cnt
);

parameter	DATA_WIDTH = 14;

input										clk,rst_n;
input				[DATA_WIDTH-1:0]	din_data,aft_data;
input										din_valid,aft_valid;
input										din_startofpacket,aft_endofpacket;
output			[DATA_WIDTH-1:0]	ram_read_addr,ram_write_addr;
output									ram_write;
input										ram_read_q;
output	reg	[DATA_WIDTH:0]		stat_cnt;

reg				[DATA_WIDTH:0]		stat_cnt_reg;
reg				[DATA_WIDTH:0]		bef1_data,bef2_data;

assign ram_read_addr = din_data;
assign ram_write_addr = aft_data;
assign ram_write = aft_valid && (~ram_read_q) && (bef1_data!={aft_valid,aft_data}) && (bef2_data!={aft_valid,aft_data});

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		stat_cnt_reg <= 'd0;
	else if(din_valid & din_startofpacket)
		stat_cnt_reg <= 'd0;
	else if(ram_write)
		stat_cnt_reg <= stat_cnt_reg + 'd1;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		stat_cnt <= 'd0;
	else if(aft_valid & aft_endofpacket)
		stat_cnt <= stat_cnt_reg;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		bef1_data <= 'd0;
	else
		bef1_data <= {aft_valid,aft_data};
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		bef2_data <= 'd0;
	else
		bef2_data <= bef1_data;
end

endmodule
	