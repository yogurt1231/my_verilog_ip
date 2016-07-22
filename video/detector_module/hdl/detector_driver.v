module detector_driver (
	clk, rst_n,
	
	av_address, av_write, av_writedata,
	
	dout_data, dout_valid,
	dout_startofpacket, dout_endofpacket
);

/* 
 * register[0][0]	go
 * register[0][1]	mode		0-image		1-background
 * register[1]		background pixel
 */

parameter DATA_WIDTH = 10;
parameter FRAME_CNT = 16'd25614;

input clk, rst_n;

input av_address;
input av_write;
input [31:0] av_writedata;

output [DATA_WIDTH-1:0]	dout_data;
output dout_valid;
output dout_startofpacket;
output dout_endofpacket;

reg 			state, n_state;

reg 			go, mode;
reg [31:0]	background;
reg [15:0]	cnt_frame;
reg [9:0]	dis_x, dis_y;
wire 			global_rst_n;
wire [15:0]	cnt_frame_add;
wire [9:0]	dis_x_add, dis_y_add;
wire [8:0]	dis_max;

localparam	IDLE = 1'b0;
localparam	DATA = 1'b1;

assign dis_max = (dis_x[9:1] > dis_y[8:0]) ? dis_x[9:1] : dis_y[8:0];
assign dout_data = mode ? background[DATA_WIDTH-1:0] : (dis_max[6:0] << (DATA_WIDTH-7));

assign global_rst_n = rst_n & go;
assign cnt_frame_add = cnt_frame + 16'd1;
assign dis_x_add = dis_x + 10'd1;
assign dis_y_add = dis_y + 10'd1;

assign dout_valid = state == DATA && dis_x < 10'd768 && dis_x[0];
assign dout_startofpacket = state == DATA && dis_x == 10'd1 && dis_y == 10'd0;
assign dout_endofpacket = state == DATA && dis_x_add == 10'd768 && dis_y_add == 10'd288;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		{mode, go} <= 2'b00;
	else if (av_write && av_address==1'b0)
		{mode, go} <= av_writedata[1:0];
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		background <= 32'd0;
	else if (av_write && av_address==1'b1)
		background <= av_writedata;
end

always @(posedge clk or negedge global_rst_n)
begin
	if (!global_rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or cnt_frame_add or dout_endofpacket)
begin
	case (state)
	IDLE: n_state = cnt_frame_add == FRAME_CNT[15:0] ? DATA : IDLE;
	DATA: n_state = dout_endofpacket ? IDLE : DATA;
	default: n_state = IDLE;
	endcase
end

always @(posedge clk or negedge global_rst_n)
begin
	if (!global_rst_n) begin
		dis_x <= 10'd0;
		dis_y <= 10'd0;
	end
	else if (state == DATA) begin
		if (dis_x_add == 10'd814) begin
			dis_x <= 10'd0;
			dis_y <= dis_y_add;
		end
		else begin
			dis_x <= dis_x_add;
			dis_y <= dis_y;
		end
	end
	else begin
		dis_x <= 10'd0;
		dis_y <= 10'd0;		
	end
end

always @(posedge clk or negedge global_rst_n)
begin
	if (!global_rst_n)
		cnt_frame <= 16'd0;
	else if (state == IDLE)
		cnt_frame <= cnt_frame_add;
	else
		cnt_frame <= 16'd0;
end

endmodule
