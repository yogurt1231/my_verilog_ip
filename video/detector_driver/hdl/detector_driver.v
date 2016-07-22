module detector_driver(
	input 			clk,
	input 			rst_n,
	
	input 			reset_n_reg,
	input 			i2c_address_reg,
	input [7:0]		interline_reg,
	
	output 			dout_startofpacket,
	output 			dout_endofpacket,
	output 			dout_valid,
	output [13:0]	dout_data,

	output 			dd_nrst,
	output 			dd_i2cad,
	output 			dd_seq_trigger,
	
	input 			dd_hsync,
	input 			dd_vsync,
	input [13:0]	dd_video
);

parameter [31:0]	FRAME_FRE_CNT	= 32'd120000;
parameter [7:0]	SEQ_TRT_WIDTH	= 8'd8;

localparam [9:0]	DIS_X	= 10'd384;
localparam [9:0]	DIS_Y	= 10'd288;

reg [2:0]	state, n_state;

wire [15:0]	video_data;
reg [7:0]	seq_tri_cnt;

reg [9:0]	video_cnt_x;
reg [9:0]	video_cnt_y;
wire [9:0]	video_add_x;
wire [9:0]	video_add_y;
wire [9:0]	interline_cnt;

reg [31:0]	frame_fre_cnt;
wire [31:0]	frame_fre_add;

localparam	SEQ_DELAY	= 3'd0;
localparam	VIDEO_TAG	= 3'd1;
localparam	VIDEO_OUT	= 3'd2;
localparam	FRAME_END	= 3'd3;

assign frame_fre_add = frame_fre_cnt + 32'd1;
assign video_add_x = video_cnt_x + 10'd1;
assign video_add_y = video_cnt_y + 10'd1;
assign interline_cnt = DIS_X + interline_reg;

assign dout_data = dd_video;
assign dout_valid = state==VIDEO_OUT && dd_hsync;
assign dout_startofpacket = dout_valid && video_cnt_x==10'd0 && video_cnt_y==10'd0;
assign dout_endofpacket = dout_valid && video_add_x==DIS_X && video_add_y==DIS_Y;

assign dd_nrst = reset_n_reg;
assign dd_i2cad = i2c_address_reg;
assign dd_seq_trigger = state==SEQ_DELAY && seq_tri_cnt<SEQ_TRT_WIDTH;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= SEQ_DELAY;
	else
		state <= n_state;
end

always @(state or dd_vsync or dout_endofpacket)
begin
	case (state)
	SEQ_DELAY: n_state = dd_vsync ? VIDEO_TAG : SEQ_DELAY;
	VIDEO_TAG: n_state = VIDEO_OUT;
	VIDEO_OUT: n_state = dout_endofpacket ? FRAME_END : VIDEO_OUT;
	FRAME_END: n_state = frame_fre_add == FRAME_FRE_CNT ? SEQ_DELAY : FRAME_END;
	default: n_state = SEQ_DELAY;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		frame_fre_cnt <= 32'd0;
	else if (frame_fre_add == FRAME_FRE_CNT)
		frame_fre_cnt <= 32'd0;
	else
		frame_fre_cnt <= frame_fre_add;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		video_cnt_x <= 10'd0;
		video_cnt_y <= 10'd0;
	end
	else if (state == VIDEO_OUT) begin
		if (dd_hsync) begin
			if (video_add_x == interline_cnt) begin
				video_cnt_x <= 10'd0;
				video_cnt_y <= video_add_y;
			end
			else begin
				video_cnt_x <= video_add_x;
				video_cnt_y <= video_cnt_y;
			end
		end
	end
	else begin
		video_cnt_x <= 10'd0;
		video_cnt_y <= 10'd0;
	end
end

endmodule
