module GB_top(
	clk,rst_n,

`ifdef RUN_CONTROL
	av_address,av_read,av_write,
	av_readdata,av_writedata,
`elsif EXPORT
	inf_ena,inf_stat,
`endif

	din_data,din_valid,din_ready,
	din_startofpacket,din_endofpacket,
	dout_data,dout_valid,dout_ready,
	dout_startofpacket,dout_endofpacket
);

parameter	DEVICE_FAMILY = "Cyclone V";

parameter	DIN_WIDTH = 14;
parameter	DOUT_WIDTH = 10;
parameter	DIV_LATENCY = 4;

input								clk,rst_n;

input		[DIN_WIDTH-1:0]	din_data;
input								din_valid;
output							din_ready;
input								din_startofpacket,din_endofpacket;

output	[DOUT_WIDTH-1:0]	dout_data;
output							dout_valid;
input								dout_ready;
output							dout_startofpacket,dout_endofpacket;

wire		[15:0]				im_width,im_height;
wire		[3:0]					im_interlaced;

wire		[DIN_WIDTH-1:0]	ori_data;
wire								ori_valid,ori_ready;
wire								ori_startofpacket,ori_endofpacket;

wire		[DIN_WIDTH-1:0]	aft_data;
wire								aft_valid;
wire								aft_startofpacket,aft_endofpacket;

wire		[DIN_WIDTH-1:0]	stat_gray_ram_read_addr;
wire								stat_gray_ram_write;
wire		[DIN_WIDTH-1:0]	stat_gray_ram_write_addr;
wire		[DIN_WIDTH:0]		stat_cnt;

wire		[DIN_WIDTH-1:0]	comp_gray_ram_read_addr;
wire								comp_gray_ram_write;
wire		[DIN_WIDTH-1:0]	comp_gray_ram_write_addr;

wire		[DIN_WIDTH-1:0]	gray_ram_read_addr;
wire								gray_ram_write;
wire		[DIN_WIDTH-1:0]	gray_ram_write_addr;
wire								gray_ram_read_q;

wire		[DIN_WIDTH-1:0]	map_ram_write_addr;
wire		[DOUT_WIDTH-1:0]	map_ram_write_data;
wire								map_ram_write;

wire		[DIN_WIDTH+DOUT_WIDTH:0]	div_numer;
wire		[DIN_WIDTH+DOUT_WIDTH:0]	div_quotient;
wire								state_comp;

wire		[DOUT_WIDTH-1:0]	fifo_data;
wire		[2:0]					fifo_usedw;
wire								fifo_empty,fifo_aclr,fifo_rdreq;

wire		[DOUT_WIDTH-1:0]	bef_data;
wire								bef_valid,bef_ready;
wire								bef_startofpacket,bef_endofpacket;

wire								global_rstn;
wire		[DOUT_WIDTH-1:0]	fin_data;

`ifdef RUN_CONTROL
input							av_address,av_read,av_write;
output	reg	[31:0]	av_readdata;
input				[31:0]	av_writedata;

reg	go,ena;
reg	[DOUT_WIDTH-1:0]	nena_data;

assign global_rstn = go & rst_n;
assign fin_data = ena ? fifo_data : nena_data;

always @(aft_data)
begin
	if(DOUT_WIDTH <= DIN_WIDTH)
		nena_data = aft_data[DIN_WIDTH-1:DIN_WIDTH-DOUT_WIDTH];
	else
	begin
		nena_data[DOUT_WIDTH-1:DOUT_WIDTH-DIN_WIDTH] = aft_data;
		nena_data[DOUT_WIDTH-DIN_WIDTH-1:0] = 'd0;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		{ena,go} <= 2'b11;
	else if(av_write & (~av_address))
		{ena,go} <= av_writedata[1:0];
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		av_readdata <= 32'd0;
	else if(av_read)
		av_readdata <= av_address ? stat_cnt : {30'd0,ena,go};
end
`elsif EXPORT
input								inf_ena;
output	[DIN_WIDTH:0]		inf_stat;

wire								ena;
reg		[DOUT_WIDTH-1:0]	nena_data;

assign ena = inf_ena;
assign global_rstn = rst_n;
assign inf_stat = stat_cnt;
assign fin_data = ena ? fifo_data : nena_data;

always @(aft_data)
begin
	if(DOUT_WIDTH <= DIN_WIDTH)
		nena_data = aft_data[DIN_WIDTH-1:DIN_WIDTH-DOUT_WIDTH];
	else
	begin
		nena_data[DOUT_WIDTH-1:DOUT_WIDTH-DIN_WIDTH] = aft_data;
		nena_data[DOUT_WIDTH-DIN_WIDTH-1:0] = 'd0;
	end
end
`else
assign global_rstn = rst_n;
assign fin_data = fifo_data;
`endif

assign ori_ready = ~(fifo_usedw[2] | state_comp);

GB_decode #(
	.DATA_WIDTH(DIN_WIDTH),
	.COLOR_BITS(DIN_WIDTH),
	.COLOR_PLANES(1))
u1 (
	.clk(clk),
	.rst_n(global_rstn),

	.din_data(din_data),
	.din_valid(din_valid),
	.din_ready(din_ready),
	.din_startofpacket(din_startofpacket),
	.din_endofpacket(din_endofpacket),

	.dout_data(ori_data),
	.dout_valid(ori_valid),
	.dout_ready(ori_ready),
	.dout_startofpacket(ori_startofpacket),
	.dout_endofpacket(ori_endofpacket),

	.im_width(im_width),
	.im_height(im_height),
	.im_interlaced(im_interlaced)
);

GB_data_delay #(
	.DATA_WIDTH(DIN_WIDTH+3),
	.DELAY_CYCLE(2))
u2 (
	.clk(clk),
	.rst_n(global_rstn),

	.datain({ori_startofpacket,ori_endofpacket,ori_valid,ori_data}),
	.dataout({aft_startofpacket,aft_endofpacket,aft_valid,aft_data})
);

GB_stat #(
	.DATA_WIDTH(DIN_WIDTH))
u3 (
	.clk(clk),
	.rst_n(global_rstn),

	.din_data(ori_data),
	.din_valid(ori_valid),
	.din_startofpacket(ori_startofpacket),

	.aft_data(aft_data),
	.aft_valid(aft_valid),
	.aft_endofpacket(aft_endofpacket),

	.ram_read_addr(stat_gray_ram_read_addr),
	.ram_read_q(gray_ram_read_q),
	.ram_write_addr(stat_gray_ram_write_addr),
	.ram_write(stat_gray_ram_write),

	.stat_cnt(stat_cnt)
);

GB_comp #(
	.DIN_WIDTH(DIN_WIDTH),
	.DOUT_WIDTH(DOUT_WIDTH),
	.WRITE_LATENCY(DIV_LATENCY+3))
u4 (
	.clk(clk),
	.rst_n(global_rstn),

	.aft_valid(aft_valid),
	.aft_endofpacket(aft_endofpacket),

	.gray_ram_read_addr(comp_gray_ram_read_addr),
	.gray_ram_read_q(gray_ram_read_q),
	.gray_ram_write_addr(comp_gray_ram_write_addr),
	.gray_ram_write(comp_gray_ram_write),

	.map_ram_write_addr(map_ram_write_addr),
	.map_ram_write_data(map_ram_write_data),
	.map_ram_write(map_ram_write),

	.div_numer(div_numer),
	.div_demon_shift(stat_cnt[DIN_WIDTH:1]),
	.div_quotient(div_quotient[DOUT_WIDTH-1:0]),

	.state_comp(state_comp)
);

GB_Gray_RAM_MUX #(
	.DATA_WIDTH(2*DIN_WIDTH+1))
u5 (
	.data0x({stat_gray_ram_write_addr,stat_gray_ram_write,stat_gray_ram_read_addr}),
	.data1x({comp_gray_ram_write_addr,comp_gray_ram_write,comp_gray_ram_read_addr}),
	.sel(state_comp),
	.result({gray_ram_write_addr,gray_ram_write,gray_ram_read_addr})
);

GB_RAM #(
	.DEVICE_FAMILY(DEVICE_FAMILY),
	.ADDR_WIDTH(DIN_WIDTH),
	.DATA_WIDTH(1))
u6_gray_ram (
	.clock(clk),
	.data(~state_comp),
	.rdaddress(gray_ram_read_addr),
	.wraddress(gray_ram_write_addr),
	.wren(gray_ram_write),
	.q(gray_ram_read_q)
);

GB_div #(
	.NUMER_WIDTH(DIN_WIDTH+DOUT_WIDTH+1),
	.DEMON_WIDTH(DIN_WIDTH+1),
	.PIPELINE(DIV_LATENCY))
u7 (
	.clock(clk),
	.numer(div_numer),
	.denom(stat_cnt),
	.quotient(div_quotient),
	.remain()	
);

GB_RAM #(
	.DEVICE_FAMILY(DEVICE_FAMILY),
	.ADDR_WIDTH(DIN_WIDTH),
	.DATA_WIDTH(DOUT_WIDTH))	
u8_map_ram (
	.clock(clk),
	.data(map_ram_write_data),
	.rdaddress(ori_data),
	.wraddress(map_ram_write_addr),
	.wren(map_ram_write),
	.q(fifo_data)
);

GB_dout_fifo #(
	.DEVICE_FAMILY(DEVICE_FAMILY),
	.DATA_WIDTH(DOUT_WIDTH+2))
u9 (
	.clock(clk),
	.data({aft_startofpacket,aft_endofpacket,fin_data}),
	.wrreq(aft_valid),
	.rdreq(fifo_rdreq),
	.q({bef_startofpacket,bef_endofpacket,bef_data}),
	.empty(fifo_empty),
	.usedw(fifo_usedw),
	.aclr(fifo_aclr)	
);

GB_read_fifo u10(
	.clk(clk),
	.rst_n(global_rstn),
	.fifo_empty(fifo_empty),
	.vst_ready(bef_ready),
	.fifo_rdreq(fifo_rdreq),
	.vst_valid(bef_valid),
	.fifo_aclr(fifo_aclr)
);

GB_encode #(
	.DATA_WIDTH(DOUT_WIDTH),
	.DATA_BITS(DOUT_WIDTH),
	.DATA_PLANES(1))
u11 (
	.clk(clk),
	.rst_n(global_rstn),

	.video_width(im_width),
	.video_height(im_height),
	.video_interlaced(im_interlaced),

	.din_data(bef_data),
	.din_valid(bef_valid),
	.din_ready(bef_ready),
	.din_startofpacket(bef_startofpacket),
	.din_endofpacket(bef_endofpacket),

	.dout_data(dout_data),
	.dout_valid(dout_valid),
	.dout_ready(dout_ready),
	.dout_startofpacket(dout_startofpacket),
	.dout_endofpacket(dout_endofpacket)
);

endmodule
