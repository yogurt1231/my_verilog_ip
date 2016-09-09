module system_qsys_detector_driver (
	input 				clk,
	input 				rst_n,
	
	input [2:0]			av_address,
	input 				av_read,
	output reg [31:0]	av_readdata,
	input 				av_write,
	input [31:0]		av_writedata,

	output 				dout_startofpacket,
	output 				dout_endofpacket,
	output 				dout_valid,
	output [13:0]		dout_data,

	output reg			dd_nrst,
	output reg			dd_i2cad,

	input 				dd_psync,
	input 				dd_hsync,
	input 				dd_vsync,
	input [13:0]		dd_video
);

/*
 * register[0][0]	go
 * register[1]		vtemp
 * register[3][0]	i2c_address
 * register[4][0]	output select 0-background 1-video
 * register[5]		background
 */

parameter AD_DELAY = 5;

wire [13:0]	vtemp_reg;
wire 			int_startofpacket;
wire 			int_endofpacket;
wire 			int_valid;

wire [13:0]	video_data;

reg 			output_select;
reg [13:0]	background;

assign dout_data = output_select ? video_data : background;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		dd_nrst <= 1'b0;
		dd_i2cad <= 1'b0;
		output_select <= 1'b0;
		background <= 14'd0;
	end
	else if (av_write) begin
		case (av_address)
		3'd0: dd_nrst <= av_writedata[0];
		3'd3: dd_i2cad <= av_writedata[0];
		3'd4: output_select <= av_writedata[0];
		3'd5: background <= av_writedata[13:0];
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		av_readdata <= 32'd0;
	else if (av_read) begin
		case (av_address)
		3'd0: av_readdata <= {31'd0, dd_nrst};
		3'd1: av_readdata <= {18'd0, vtemp_reg};
		3'd3: av_readdata <= {31'd0, dd_i2cad};
		default: av_readdata <= 32'd0;
		endcase
	end
end

detector_driver u3(
	.clk(dd_psync),
	.rst_n(rst_n),

	.vtemp_reg(vtemp_reg),
	
	.dout_startofpacket(int_startofpacket),
	.dout_endofpacket(int_endofpacket),
	.dout_valid(int_valid),
	.dout_data(video_data),
	
	.dd_hsync(dd_hsync),
	.dd_vsync(dd_vsync),
	.dd_video(dd_video)
);

detector_delay #(
	.DATA_WIDTH(3),
	.DELAY_CYCLE(AD_DELAY))
u4 (
	.clk(dd_psync),
	.rst_n(rst_n),
	.datain({int_startofpacket, int_endofpacket, int_valid}),
	.dataout({dout_startofpacket, dout_endofpacket, dout_valid})
);

endmodule
