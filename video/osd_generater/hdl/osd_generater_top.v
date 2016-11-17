module osd_generater_top(
	clk, rst_n,
	
	av_address,
	av_read, av_write,
	av_readdata, av_writedata,
	
	am_address, am_read,
	am_readdata, am_readdatavalid,
	am_waitrequest, am_byteenable,
	
	dout_data, dout_valid,
	dout_ready,
	dout_startofpacket,
	dout_endofpacket
);

parameter		DATA_LOG		= 3;
parameter		DOUT_WIDTH	= 10;

input 			clk, rst_n;

input [2:0]		av_address;
input 			av_read, av_write;
output [31:0]	av_readdata;
input [31:0]	av_writedata;

output [31:0]	am_address;
output 			am_read;
input [(1<<DATA_LOG)-1:0] am_readdata;
input 			am_readdatavalid;
input 			am_waitrequest;
output [(1<<(DATA_LOG-3))-1:0]	am_byteenable;

output [DOUT_WIDTH-1:0]	dout_data;
output 						dout_valid;
input 						dout_ready;
output 						dout_startofpacket;
output 						dout_endofpacket;

/*
 * register[0][0]	go
 * register[1]		reverse
 * register[2]		read address
 * register[3]		osd pixels
 * register[4]		osd width
 * register[5]		osd height
 * register[6]		osd dataA
 * register[7]		osd dataB
 */

wire	[31:0]	registers [7:0];
wire				global_rst_n = rst_n & registers[0][0];

wire				raw_data, raw_valid;
wire				raw_startofpacket, raw_endofpacket;

wire				rst_ready, rst_valid;

wire 						pixel_fifo_aclr;
wire 						pixel_fifo_rdreq;
wire 						pixel_fifo_empty;
wire [2:0]				pixel_fifo_q;
wire [DATA_LOG+1:0]	pixel_fifo_usedw;

osd_avalon_slave #(
	.ADDR_WIDTH(3))
osd_inst_0 (
	.clk(clk),
	.rst_n(rst_n),

	.av_address(av_address),
	.av_read(av_read),
	.av_write(av_write),
	.av_readdata(av_readdata),
	.av_writedata(av_writedata),

	.conduit_signal({	registers[7],registers[6],registers[5],registers[4],
							registers[3],registers[2],registers[1],registers[0]})
);

osd_avalon_read_module #(
	.DATA_LOG(DATA_LOG))
osd_inst_1 (
	.clk(clk),
	.rst_n(global_rst_n),
	
	.frame_addr(registers[2]),
	.frame_num(registers[3]),
	
	.am_address(am_address),
	.am_read(am_read),
	.am_readdata(am_readdata),
	.am_readdatavalid(am_readdatavalid),
	.am_waitrequest(am_waitrequest),
	.am_byteenable(am_byteenable),

	.dout_data(raw_data),
	.dout_valid(raw_valid),
	.dout_ready(~pixel_fifo_usedw[DATA_LOG+1]),
	.dout_startofpacket(raw_startofpacket),
	.dout_endofpacket(raw_endofpacket)
);

osd_pixel_fifo #(
	.DEPTH_WIDTH(DATA_LOG+2))
osd_inst_2 (
	.clock(clk),
	.aclr(pixel_fifo_aclr),
	
	.rdreq(pixel_fifo_rdreq),
	.q(pixel_fifo_q),	
	
	.wrreq(raw_valid),
	.data({raw_startofpacket, raw_endofpacket, raw_data}),

	.empty(pixel_fifo_empty),
	.usedw(pixel_fifo_usedw)
);

osd_read_fifo osd_inst_3 (
	.clk(clk),
	.rst_n(global_rst_n),
	
	.fifo_empty(pixel_fifo_empty),
	.fifo_rdreq(pixel_fifo_rdreq),
	.fifo_aclr(pixel_fifo_aclr),
	
	.vst_ready(rst_ready),
	.vst_valid(rst_valid)
);

osd_encode #(
	.DATA_WIDTH(DOUT_WIDTH),
	.DATA_BITS(DOUT_WIDTH),
	.DATA_PLANES(1)
)
osd_inst_4 (
	.clk(clk),
	.rst_n(global_rst_n),

	.video_width(registers[4][15:0]),
	.video_height(registers[5][15:0]),
	.video_interlaced(4'b0010),

	.din_data(pixel_fifo_q[0] ? registers[6][DOUT_WIDTH-1:0] : registers[7][DOUT_WIDTH-1:0]),
	.din_valid(rst_valid),
	.din_ready(rst_ready),
	.din_startofpacket(pixel_fifo_q[2]),
	.din_endofpacket(pixel_fifo_q[1]),

	.dout_data(dout_data),
	.dout_valid(dout_valid),
	.dout_ready(dout_ready),
	.dout_startofpacket(dout_startofpacket),
	.dout_endofpacket(dout_endofpacket)
);

endmodule
