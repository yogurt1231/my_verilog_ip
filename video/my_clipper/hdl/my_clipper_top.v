module my_clipper_top(

`ifdef RUNTIME_CONTROL
	av_clk,av_rst_n,
	av_address,av_read,av_write,
	av_readdata,av_readdatavalid,
	av_writedata,av_waitrequest,
`endif

	vst_clk,vst_rst_n,
	
	din_data,din_ready,din_valid,
	din_startofpacket,din_endofpacket,
	
	dout_data,dout_ready,dout_valid,
	dout_startofpacket,dout_endofpacket
);

parameter						DATA_WIDTH		= 24;
parameter						COLOR_BITS		= 8;
parameter						COLOR_PLANES	= 3;

parameter						USED_WIDTH		= 12;

parameter						LEFT_OFFSET		= 16'd24;
parameter						RIGHT_OFFSET	= 16'd24;
parameter						TOP_OFFSET		= 16'd0;
parameter						BOTTOM_OFFSET	= 16'd0;

`ifdef RUNTIME_CONTROL
input								av_clk,av_rst_n;
input				[2:0]			av_address;
input								av_read,av_write;
output	reg	[31:0]		av_readdata;
output	reg					av_readdatavalid;
output							av_waitrequest;
input				[31:0]		av_writedata;
`endif

input								vst_clk,vst_rst_n;

input		[DATA_WIDTH-1:0]	din_data;
input								din_valid,din_startofpacket,din_endofpacket;
output							din_ready;

output	[DATA_WIDTH-1:0]	dout_data;
output							dout_valid,dout_startofpacket,dout_endofpacket;
input								dout_ready;

wire								glo_rst_n;
wire		[USED_WIDTH-1:0]	fifo_usedw;
wire		[DATA_WIDTH+1:0]	fifo_data,fifo_q;
wire								fifo_wrreq,fifo_rdreq,fifo_aclr,fifo_empty;
wire								vst_valid,vst_ready;
wire		[15:0]				video_height,video_width;
wire		[3:0]					video_interlaced;

`ifdef RUNTIME_CONTROL
reg		[15:0]				left_offset;
reg		[15:0]				right_offset;
reg		[15:0]				top_offset;
reg		[15:0]				bottom_offset;
reg								go;
reg								status;
wire								vrst_n;

assign av_waitrequest = 1'b0;
assign vrst_n = vst_rst_n & go;
assign glo_rst_n = vrst_n;

always @(posedge av_clk or negedge av_rst_n)
begin
	if(!av_rst_n)
	begin
		go <= 1'b1;
		left_offset <= LEFT_OFFSET[15:0];
		right_offset <= RIGHT_OFFSET[15:0];
		top_offset <= TOP_OFFSET[15:0];
		bottom_offset <= BOTTOM_OFFSET[15:0];		
	end
	else if(av_write)
	begin
		case(av_address)
		3'd0:go <= av_writedata[0];
		3'd3:left_offset <= av_writedata[15:0];
		3'd4:right_offset <= av_writedata[15:0];
		3'd5:top_offset <= av_writedata[15:0];
		3'd6:bottom_offset <= av_writedata[15:0];
		endcase
	end
end

always @(posedge av_clk or negedge av_rst_n)
begin
	if(!av_rst_n)
		status <= 1'b0;
	else if(din_startofpacket)
		status <= 1'b1;
	else if(din_endofpacket)
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
		3'd0:av_readdata <= {31'd0,go};
		3'd1:av_readdata <= {31'd0,status};
		3'd3:av_readdata <= {16'd0,left_offset};
		3'd4:av_readdata <= {16'd0,right_offset};
		3'd5:av_readdata <= {16'd0,top_offset};
		3'd6:av_readdata <= {16'd0,bottom_offset};
		default:av_readdata <= 32'd0;
		endcase
	end
end
`else
assign glo_rst_n = vst_rst_n;
`endif

my_clipper_decode #(
	.DATA_WIDTH(DATA_WIDTH),
	.COLOR_BITS(COLOR_BITS),
	.COLOR_PLANES(COLOR_PLANES),
	.USE_WIDTH(USED_WIDTH))
u1 (
	.clk(vst_clk),
	.rst_n(glo_rst_n),
	
`ifdef RUNTIME_CONTROL
	.LEFT_OFFSET(left_offset),
	.RIGHT_OFFSET(right_offset),
	.TOP_OFFSET(top_offset),
	.BOTTOM_OFFSET(bottom_offset),
`else
	.LEFT_OFFSET(LEFT_OFFSET[15:0]),
	.RIGHT_OFFSET(RIGHT_OFFSET[15:0]),
	.TOP_OFFSET(TOP_OFFSET[15:0]),
	.BOTTOM_OFFSET(BOTTOM_OFFSET[15:0]),
`endif

	.din_data(din_data),
	.din_valid(din_valid),
	.din_startofpacket(din_startofpacket),
	.din_endofpacket(din_endofpacket),
	.din_ready(din_ready),
	.fifo_usedw(fifo_usedw),
	.fifo_data(fifo_data),
	.fifo_wrreq(fifo_wrreq),
	.im_width(video_width),
	.im_height(video_height),
	.im_interlaced(video_interlaced));

my_clipper_fifo #(
	.DATA_WIDTH(DATA_WIDTH+2),
	.USED_WIDTH(USED_WIDTH))
u2 (
	.clock(vst_clk),
	.data(fifo_data),
	.wrreq(fifo_wrreq),
	.q(fifo_q),
	.rdreq(fifo_rdreq),
	.usedw(fifo_usedw),
	.empty(fifo_empty),
	.aclr(fifo_aclr));
	
my_clipper_read_fifo u3 (
	.clk(vst_clk),
	.rst_n(glo_rst_n),
	.fifo_empty(fifo_empty),
	.vst_ready(vst_ready),
	.fifo_rdreq(fifo_rdreq),
	.vst_valid(vst_valid),
	.fifo_aclr(fifo_aclr));

my_clipper_encode #(
	.DATA_WIDTH(DATA_WIDTH),
	.DATA_BITS(COLOR_BITS),
	.DATA_PLANES(COLOR_PLANES))
u4 (
	.clk(vst_clk),
	.rst_n(glo_rst_n),
	.video_width(video_width),
	.video_height(video_height),
	.video_interlaced(video_interlaced),
	.din_data(fifo_q[DATA_WIDTH-1:0]),
	.din_valid(vst_valid),
	.din_startofpacket(fifo_q[DATA_WIDTH+1]),
	.din_endofpacket(fifo_q[DATA_WIDTH]),
	.din_ready(vst_ready),
	.dout_data(dout_data),
	.dout_valid(dout_valid),
	.dout_startofpacket(dout_startofpacket),
	.dout_endofpacket(dout_endofpacket),
	.dout_ready(dout_ready));

endmodule
