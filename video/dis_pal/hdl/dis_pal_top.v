module dis_pal_top(
	vst_clk, vst_rst_n,
	vst_data, vst_valid, vst_ready,
	vst_startofpacket, vst_endofpacket,
	
`ifdef EXPORT_CNT
	if_cnt_x, if_cnt_y,
`endif

	dis_clk, dis_data,
	dis_sync_n, dis_blank_n
);

parameter	DATA_WIDTH				= 10;

parameter	FRAME_NUM				= 24'd2_000_000;
parameter	THRESHOLD_A				= 24'd1_929_600;
parameter	THRESHOLD_B				= 24'd0_003_200;
parameter	THRESHOLD_C				= 24'd0_928_000;
parameter	THRESHOLD_D				= 24'd1_004_800;

parameter	PAL_CNT_X				= 10'd864;
parameter	PAL_BLANK_H_BEFORE	= 10'd126;
parameter	PAL_DIS_X				= 10'd720;
parameter	PAL_SYNC_SLOT			= 10'd64;

input 						vst_clk, vst_rst_n;
input [DATA_WIDTH-1:0]	vst_data;
input 						vst_valid;
input 						vst_startofpacket, vst_endofpacket;
output 						vst_ready;

input 						dis_clk;
output [DATA_WIDTH-1:0]	dis_data;
output 						dis_sync_n, dis_blank_n;

`ifdef EXPORT_CNT
output [9:0]	if_cnt_x;
output [9:0]	if_cnt_y;
`endif

wire 	[DATA_WIDTH-1:0]	fifo_data;
wire 							fifo_wrreq, fifo_aclr;
wire 	[9:0]					fifo_usedw;
wire 							dis_rst_n;

wire 							fifo_rdreq;
wire 	[DATA_WIDTH-1:0]	fifo_q;

wire 	[DATA_WIDTH-1:0]	raw_data;
wire 							raw_valid, raw_ready;
wire 							raw_startofpacket;
wire 							raw_endofpackt;

dis_pal_decode #(
	.DATA_WIDTH(DATA_WIDTH),
	.COLOR_BITS(DATA_WIDTH),
	.COLOR_PLANES(1))
u1(
	.clk(vst_clk),
	.rst_n(vst_rst_n),
	
	.din_data(vst_data),
	.din_valid(vst_valid),
	.din_ready(vst_ready),
	.din_startofpacket(vst_startofpacket),
	.din_endofpacket(vst_endofpacket),
	
	.dout_data(raw_data),
	.dout_valid(raw_valid),
	.dout_ready(raw_ready),
	.dout_startofpacket(raw_startofpacket),
	.dout_endofpacket(raw_endofpacket),
	
	.im_width(),
	.im_height(),
	.im_interlaced());

dis_pal_process_data #(
	.DATA_WIDTH(DATA_WIDTH),
	.PAL_WIDTH(PAL_DIS_X),
	.FRAME_NUM(FRAME_NUM),
	.THRESHOLD_A(THRESHOLD_A),
	.THRESHOLD_B(THRESHOLD_B),
	.THRESHOLD_C(THRESHOLD_C),
	.THRESHOLD_D(THRESHOLD_D))
u2 (
	.vst_clk(vst_clk),
	.vst_rst_n(vst_rst_n),
	
	.vst_data(raw_data),
	.vst_valid(raw_valid),
	.vst_startofpacket(raw_startofpacket),
	.vst_endofpacket(raw_endofpacket),
	.vst_ready(raw_ready),
	
	.fifo_data(fifo_data),
	.fifo_wrreq(fifo_wrreq),
	.fifo_aclr(fifo_aclr),
	.fifo_usedw(fifo_usedw),

	.dis_rst_n(dis_rst_n));

dis_pal_pixel_fifo #(
	.DATA_WIDTH(DATA_WIDTH))
u3 (
	.wrclk(vst_clk),
	.wrreq(fifo_wrreq),
	.data(fifo_data),
	.wrusedw(fifo_usedw),
	.rdclk(dis_clk),
	.rdreq(fifo_rdreq),
	.q(fifo_q),
	.aclr(fifo_aclr));

dis_pal_buff2pal #(
	.DATA_WIDTH(DATA_WIDTH),
	.CNT_X(PAL_CNT_X),
	.BLANK_H_BEFORE(PAL_BLANK_H_BEFORE),
	.DIS_X(PAL_DIS_X),
	.SYNC_SLOT(PAL_SYNC_SLOT))
u4 (
	.dis_clk(dis_clk),
	.dis_rst_n(vst_rst_n & dis_rst_n),
	.dis_data(dis_data),
	.dis_sync_n(dis_sync_n),
	.dis_blank_n(dis_blank_n),

`ifdef EXPORT_CNT
	.if_cnt_x(if_cnt_x),
	.if_cnt_y(if_cnt_y),
`else
	.if_cnt_x(),
	.if_cnt_y(),
`endif

	.fifo_rdreq(fifo_rdreq),
	.fifo_q(fifo_q));

endmodule
