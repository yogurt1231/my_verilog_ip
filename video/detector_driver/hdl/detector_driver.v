module detector_driver(
	input 				clk,
	input 				rst_n,

	output reg [13:0]	vtemp_reg,
	
	output 				dout_startofpacket,
	output 				dout_endofpacket,
	output 				dout_valid,
	output [13:0]		dout_data,
	
	input 				dd_hsync,
	input 				dd_vsync,
	input [13:0]		dd_video
);

localparam [9:0]	DIS_X			= 10'd384;
localparam [9:0]	DIS_Y			= 10'd288;
localparam [5:0]	VTEMP_POINT	= 6'd16;

reg [5:0]	vtemp_cnt;
wire [5:0]	vtemp_add;
reg [9:0]	video_cnt_x;
reg [9:0]	video_cnt_y;
wire [9:0]	video_add_x;
wire [9:0]	video_add_y;

assign vtemp_add		= vtemp_cnt + 6'd1;
assign video_add_x	= video_cnt_x + 10'd1;
assign video_add_y	= video_cnt_y + 10'd1;

assign dout_data				= dd_video;
assign dout_valid				= dd_hsync;
assign dout_startofpacket	= dd_hsync && video_cnt_x==10'd0 && video_cnt_y==10'd0;
assign dout_endofpacket		= dd_hsync && video_add_x==DIS_X && video_add_y==DIS_Y;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		vtemp_cnt <= 6'd0;
	else
		vtemp_cnt <= dd_hsync ? 6'd0 : vtemp_add;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		vtemp_reg <= 14'd0;
	else if (vtemp_add == VTEMP_POINT)
		vtemp_reg <= dd_video;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n) begin
		video_cnt_x <= 10'd0;
		video_cnt_y <= 10'd0;
	end
	else if (dd_vsync) begin
		if (dd_hsync) begin
			if (video_add_x == DIS_X) begin
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
