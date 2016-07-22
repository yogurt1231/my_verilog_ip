module detector_driver_top(
	input 			clk,
	input 			rst_n,
	
	input [2:0]		av_address,
	input 			av_read,
	output [31:0]	av_readdata,
	input 			av_write,
	input [31:0]	av_writedata,

	output 			dout_startofpacket,
	output 			dout_endofpacket,
	output 			dout_valid,
	output [13:0]	dout_data,

	output 			dd_nrst,
	output 			dd_i2cad,
	output 			dd_seq_trigger,
	
	input 			dd_psync,
	input 			dd_hsync,
	input 			dd_vsync,
	input [13:0]	dd_video
);

parameter FRAME_FRE_CNT	= 32'd120000;
parameter SEQ_TRT_WIDTH	= 8'd8;

wire [31:0] registers [7:0];
wire [15:0]	video_data;

detector_avalon_slave #(
	.ADDR_WIDTH(3),
	.REGS_STATE(8'h00),
	.REGS_NUM(8)
u1 (
	.clk(clk),
	.rst_n(rst_n),

	.av_address(av_address),
	.av_read(av_read),
	.av_write(av_write),
	.av_readdata(av_readdata),
	.av_writedata(av_writedata),
	
	.register_signal_in(),
	.register_signal_out({registers[7],
								registers[6],
								registers[5],
								registers[4],
								registers[3],
								registers[2],
								registers[1],
								registers[0]})
);

detector_ddio_in u2(
	.inclock(dd_psync),
	.aclr(~rst_n),
	
	.datain(dd_video),

	.dataout_h(video_data[7:0]),
	.dataout_l(video_data[15:8])
);

detector_driver #(
	.FRAME_FRE_CNT(FRAME_FRE_CNT),
	.SEQ_TRT_WIDTH(SEQ_TRT_WIDTH))
u3 (
	.clk(dd_psync),
	.rst_n(rst_n),
		
	.reset_n_reg(registers[0][0]),
	.i2c_address_reg(registers[3][0]),
	.interline_reg(registers[4]),

	.dout_startofpacket(dout_startofpacket),
	.dout_endofpacket(dout_endofpacket),
	.dout_valid(dout_valid),
	.dout_data(dout_data),

	.dd_nrst(dd_nrst),
	.dd_i2cad(dd_i2cad),
	.dd_seq_trigger(dd_seq_trigger),
		
	.dd_hsync(dd_hsync),
	.dd_vsync(dd_vsync),
	.dd_video(video_data[13:0])
);

endmodule
