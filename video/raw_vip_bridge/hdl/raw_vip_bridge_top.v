module raw_vip_bridge_top(
`ifdef DATAIN_MOD_FS_SAME_CLOCK
	raw_data,raw_fs,
`elsif DATAIN_MOD_FS_NOT_SAME_CLOCK
	raw_clk,raw_rst_n,
	raw_data,raw_fs,
`elsif DATAIN_MOD_PART_ST_SAME_CLOCK
	raw_data,raw_valid,
	raw_startofpacket,raw_endofpacket,
`elsif DATAIN_MOD_PART_ST_NOT_SAME_CLOCK
	raw_clk,raw_rst_n,
	raw_data,raw_valid,
	raw_startofpacket,raw_endofpacket,
`elsif DATAIN_MOD_RAW_ST
	raw_data,raw_valid,raw_ready,
	raw_startofpacket,raw_endofpacket,
`endif

`ifdef RUNTIME_CONTROL
	av_clk,av_rst_n,
	av_address,av_read,av_write,
	av_readdata,av_readdatavalid,
	av_writedata,av_waitrequest,av_irq,
`elsif EXPORT_INF
	im_width,im_height,
	im_interlaced,
`endif

`ifdef FIFO_USEDW
	fifo_usedw,
`endif

	vst_clk,vst_rst_n,
	dout_data,dout_valid,dout_ready,
	dout_startofpacket,dout_endofpacket
);

parameter								DATA_WIDTH				= 8;
parameter								DATA_BITS				= 8;
parameter								DATA_PLANES				= 1;

parameter								FIFO_USED_WIDTH		= 12;

parameter								VIP_WIDTH				= 16'd720;
parameter								VIP_HEIGHT				= 16'd576;
parameter								VIP_INTERLACED			= 4'b0010;

input										vst_clk,vst_rst_n;

output	[DATA_WIDTH-1:0]			dout_data;
output									dout_valid,dout_startofpacket,dout_endofpacket;
input										dout_ready;

wire		[DATA_WIDTH-1:0]			rst_data;
wire										rst_valid,rst_ready;
wire										rst_startofpacket,rst_endofpacket;

wire										global_rst_n;

`ifdef RUNTIME_CONTROL
input										av_clk,av_rst_n;
input		[2:0]							av_address;
input										av_read,av_write;
input		[31:0]						av_writedata;
output	reg	[31:0]				av_readdata;
output	reg							av_readdatavalid;
output									av_irq,av_waitrequest;

reg										irqen,go,status,irq_reg;
reg		[15:0]						width,height;
reg		[3:0]							interlaced;
`elsif EXPORT_INF
input		[15:0]						im_width,im_height;
input		[3:0]							im_interlaced;
`endif

`ifdef FIFO_USEDW
output	[FIFO_USED_WIDTH-1:0]	fifo_usedw;
`endif

`ifdef DATAIN_MOD_FS_SAME_CLOCK
input		[DATA_WIDTH-1:0]			raw_data;
input										raw_fs;

wire		[DATA_WIDTH-1:0]			pst_data;
wire										pst_valid,pst_startofpacket,pst_endofpacket;

wire										fifo_empty,fifo_rdreq,fifo_aclr;
wire		[FIFO_USED_WIDTH-1:0]	fifo_usedw;

rvbridge_make_se #(
	.DATA_WIDTH(DATA_WIDTH))
u1 (
	.clk(vst_clk),
	.rst_n(global_rst_n),
	.raw_data(raw_data),
	.raw_fs(raw_fs),
	.st_data(pst_data),
	.st_valid(pst_valid),
	.st_startofpacket(pst_startofpacket),
	.st_endofpacket(pst_endofpacket));
	
rvbridge_fifo_pixel_sc #(
	.DATA_WIDTH(DATA_WIDTH+2),
	.USED_WIDTH(FIFO_USED_WIDTH))
u2 (
	.clock(vst_clk),
	.data({pst_startofpacket,pst_endofpacket,pst_data}),
	.wrreq(pst_valid),
	.rdreq(fifo_rdreq),
	.aclr(fifo_aclr),
	.q({rst_startofpacket,rst_endofpacket,rst_data}),
	.empty(fifo_empty),
	.usedw(fifo_usedw));

rvbridge_read_fifo u3(
	.clk(vst_clk),
	.rst_n(global_rst_n),
	.fifo_empty(fifo_empty),
	.vst_ready(rst_ready),
	.fifo_rdreq(fifo_rdreq),
	.vst_valid(rst_valid),
	.fifo_aclr(fifo_aclr));
`endif

`ifdef DATAIN_MOD_PART_ST_SAME_CLOCK
input		[DATA_WIDTH-1:0]			raw_data;
input										raw_valid,raw_startofpacket,raw_endofpacket;

wire										fifo_empty,fifo_rdreq,fifo_aclr;
wire		[FIFO_USED_WIDTH-1:0]	fifo_usedw;

rvbridge_fifo_pixel_sc #(
	.DATA_WIDTH(DATA_WIDTH+2),
	.USED_WIDTH(FIFO_USED_WIDTH))
u2 (
	.clock(vst_clk),
	.data({raw_startofpacket,raw_endofpacket,raw_data}),
	.wrreq(raw_valid),
	.rdreq(fifo_rdreq),
	.aclr(fifo_aclr),
	.q({rst_startofpacket,rst_endofpacket,rst_data}),
	.empty(fifo_empty),
	.usedw(fifo_usedw));

rvbridge_read_fifo u3(
	.clk(vst_clk),
	.rst_n(global_rst_n),
	.fifo_empty(fifo_empty),
	.vst_ready(rst_ready),
	.fifo_rdreq(fifo_rdreq),
	.vst_valid(rst_valid),
	.fifo_aclr(fifo_aclr));
`endif

`ifdef DATAIN_MOD_FS_NOT_SAME_CLOCK
input										raw_clk,raw_rst_n;
input		[DATA_WIDTH-1:0]			raw_data;
input										raw_fs;

wire		[DATA_WIDTH-1:0]			pst_data;
wire										pst_valid,pst_startofpacket,pst_endofpacket;

wire										fifo_empty,fifo_rdreq,fifo_aclr;
wire		[FIFO_USED_WIDTH-1:0]	fifo_usedw;

rvbridge_make_se #(
	.DATA_WIDTH(DATA_WIDTH))
u1 (
	.clk(raw_clk),
	.rst_n(raw_rst_n),
	.raw_data(raw_data),
	.raw_fs(raw_fs),
	.st_data(pst_data),
	.st_valid(pst_valid),
	.st_startofpacket(pst_startofpacket),
	.st_endofpacket(pst_endofpacket));

rvbridge_fifo_pixel_dc #(
	.DATA_WIDTH(DATA_WIDTH+2),
	.USED_WIDTH(FIFO_USED_WIDTH))
u2 (
	.wrclk(raw_clk),
	.wrreq(pst_valid),
	.rdclk(vst_clk),
	.rdreq(fifo_rdreq),
	.aclr(fifo_aclr),
	.data({pst_startofpacket,pst_endofpacket,pst_data}),
	.q({rst_startofpacket,rst_endofpacket,rst_data}),
	.rdempty(fifo_empty),
	.rdusedw(fifo_usedw));

rvbridge_read_fifo u3(
	.clk(vst_clk),
	.rst_n(global_rst_n),
	.fifo_empty(fifo_empty),
	.vst_ready(rst_ready),
	.fifo_rdreq(fifo_rdreq),
	.vst_valid(rst_valid),
	.fifo_aclr(fifo_aclr));
`endif

`ifdef DATAIN_MOD_PART_ST_NOT_SAME_CLOCK
input										raw_clk,raw_rst_n;
input		[DATA_WIDTH-1:0]			raw_data;
input										raw_valid,raw_startofpacket,raw_endofpacket;

wire										fifo_empty,fifo_rdreq,fifo_aclr;
wire		[FIFO_USED_WIDTH-1:0]	fifo_usedw;

rvbridge_fifo_pixel_dc #(
	.DATA_WIDTH(DATA_WIDTH+2),
	.USED_WIDTH(FIFO_USED_WIDTH))
u2 (
	.wrclk(raw_clk),
	.wrreq(raw_valid),
	.rdclk(vst_clk),
	.rdreq(fifo_rdreq),
	.aclr(fifo_aclr),
	.data({raw_startofpacket,raw_endofpacket,raw_data}),
	.q({rst_startofpacket,rst_endofpacket,rst_data}),
	.rdempty(fifo_empty),
	.rdusedw(fifo_usedw));

rvbridge_read_fifo u3(
	.clk(vst_clk),
	.rst_n(global_rst_n),
	.fifo_empty(fifo_empty),
	.vst_ready(rst_ready),
	.fifo_rdreq(fifo_rdreq),
	.vst_valid(rst_valid),
	.fifo_aclr(fifo_aclr));
`endif

`ifdef DATAIN_MOD_RAW_ST
input		[DATA_WIDTH-1:0]	raw_data;
input								raw_valid,raw_startofpacket,raw_endofpacket;
output							raw_ready;

assign rst_data				= raw_data;
assign rst_startofpacket	= raw_startofpacket;
assign rst_endofpacket		= raw_endofpacket;
assign rst_valid				= raw_valid;
assign raw_ready				= rst_ready;
`endif

`ifdef RUNTIME_CONTROL
assign av_irq = irqen & irq_reg;
assign av_waitrequest = 1'b0;
assign global_rst_n = vst_rst_n & go;

always @(posedge av_clk or negedge av_rst_n)
begin
	if(!av_rst_n)
	begin
		irqen <= 1'b0;
		irq_reg <= 1'b0;
		go <= 1'b1;
		width <= VIP_WIDTH[15:0];
		height <= VIP_HEIGHT[15:0];
		interlaced <= VIP_INTERLACED[3:0];
	end
	else if(av_write)
	begin
		case(av_address)
		3'd0:{irqen,go} <= av_writedata[1:0];
		3'd2:irq_reg <= 1'b0;
		3'd3:width <= av_writedata[15:0];
		3'd4:height <= av_writedata[15:0];
		3'd5:interlaced <= av_writedata[3:0];
		endcase
	end
	else if(rst_endofpacket & rst_valid)
		irq_reg <= 1'b1;
end

always @(posedge av_clk or negedge av_rst_n)
begin
	if(!av_rst_n)
		status <= 1'b0;
	else if(rst_startofpacket)
		status <= 1'b1;
	else if(rst_endofpacket)
		status <= 1'b0;
	else
		status <= status;
end

always @(posedge av_clk or negedge av_rst_n)
begin
	if(!av_rst_n)
		av_readdatavalid <= 1'b0;
	else if(av_read)
		av_readdatavalid <= 1'b1;
	else
		av_readdatavalid <= 1'b0;
end

always @(posedge av_clk or negedge av_rst_n)
begin
	if(!av_rst_n)
		av_readdata <= 32'd0;
	else if(av_read)
	begin
		case(av_address)
		3'd0:av_readdata <= {30'd0,irqen,go};
		3'd1:av_readdata <= {31'd0,status};
		3'd2:av_readdata <= {31'd0,av_irq};
		3'd3:av_readdata <= {16'd0,width};
		3'd4:av_readdata <= {16'd0,height};
		3'd5:av_readdata <= {28'd0,interlaced};
		default:av_readdata <= 32'd0;
		endcase
	end
end
`else
assign global_rst_n = vst_rst_n;
`endif

rvbridge_encode #(
	.DATA_WIDTH(DATA_WIDTH),
	.DATA_BITS(DATA_BITS),
	.DATA_PLANES(DATA_PLANES))
u4 (
	.clk(vst_clk),
	.rst_n(global_rst_n),

`ifdef RUNTIME_CONTROL
	.video_width(width),
	.video_height(height),
	.video_interlaced(interlaced),
`elsif EXPORT_INF
	.video_width(im_width),
	.video_height(im_height),
	.video_interlaced(im_interlaced),
`else
	.video_width(VIP_WIDTH[15:0]),
	.video_height(VIP_HEIGHT[15:0]),
	.video_interlaced(VIP_INTERLACED[3:0]),
`endif
	
	.din_data(rst_data),
	.din_valid(rst_valid),
	.din_startofpacket(rst_startofpacket),
	.din_endofpacket(rst_endofpacket),
	.din_ready(rst_ready),
	
	.dout_data(dout_data),
	.dout_valid(dout_valid),
	.dout_startofpacket(dout_startofpacket),
	.dout_endofpacket(dout_endofpacket),
	.dout_ready(dout_ready));

endmodule
