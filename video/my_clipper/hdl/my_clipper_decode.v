module my_clipper_decode(
	clk,rst_n,

	LEFT_OFFSET,RIGHT_OFFSET,TOP_OFFSET,BOTTOM_OFFSET,

	din_data,din_valid,din_ready,
	din_startofpacket,din_endofpacket,

	fifo_usedw,fifo_data,fifo_wrreq,

	im_width,im_height,im_interlaced
);

parameter						DATA_WIDTH		= 24;
parameter						COLOR_BITS		= 8;
parameter						COLOR_PLANES	= 3;

parameter						USE_WIDTH		= 6;

input								clk,rst_n;

input		[15:0]				LEFT_OFFSET,RIGHT_OFFSET,TOP_OFFSET,BOTTOM_OFFSET;

input		[DATA_WIDTH-1:0]	din_data;
input								din_valid,din_startofpacket,din_endofpacket;
output							din_ready;

input		[USE_WIDTH-1:0]	fifo_usedw;
output	[DATA_WIDTH+1:0]	fifo_data;
output							fifo_wrreq;

output	[15:0]				im_width,im_height;
output	[3:0]					im_interlaced;

reg		[15:0]				left_offset,right_offset,top_offset,bottom_offset;

reg		[15:0]				dis_width,dis_height;
reg		[3:0]					dis_interlaced;

reg		[2:0]					state,n_state;
reg		[3:0]					control_cnt;
reg		[15:0]				dis_cnt_x,dis_cnt_y;

wire								inside_valid;
wire								st_startofpacket,st_endofpacket;

localparam IDLE = 3'b001;
localparam CTRL = 3'b010;
localparam DATA = 3'b100;

assign im_width			= dis_width - left_offset - right_offset;
assign im_height			= dis_height - top_offset - bottom_offset;
assign im_interlaced		= dis_interlaced;

assign st_startofpacket	= (dis_cnt_x==left_offset) && (dis_cnt_y==top_offset);
assign st_endofpacket	= ((dis_cnt_x+16'd1)==(dis_width-right_offset)) && ((dis_cnt_y+16'd1)==(dis_height-bottom_offset));
assign inside_valid		= (dis_cnt_x>=left_offset) && (dis_cnt_x<(dis_width-right_offset)) && (dis_cnt_y>=top_offset) && (dis_cnt_y<(dis_height-bottom_offset));

assign din_ready			= ~(&fifo_usedw[USE_WIDTH-1:4]);
assign fifo_data			= {st_startofpacket,st_endofpacket,din_data};
assign fifo_wrreq			= state==DATA && din_valid && inside_valid;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		left_offset <= 16'd0;
		right_offset <= 16'd0;
		top_offset <= 16'd0;
		bottom_offset <= 16'd0;
	end
	else if(state==IDLE && n_state==CTRL)
	begin
		left_offset <= LEFT_OFFSET;
		right_offset <= RIGHT_OFFSET;
		top_offset <= TOP_OFFSET;
		bottom_offset <= BOTTOM_OFFSET;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or din_valid or din_startofpacket or din_endofpacket or din_data[3:0])
begin
	case(state)
	IDLE:begin
		if(din_valid & din_startofpacket)
		begin
			case(din_data[3:0])
			4'hF:n_state = CTRL;
			3'h0:n_state = DATA;
			default:n_state = IDLE;
			endcase
		end
		else
			n_state = IDLE;
	end
	CTRL,DATA:n_state = (din_valid & din_endofpacket) ? IDLE : state;
	default:n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		control_cnt <= 4'd0;
	else if(state==CTRL)
		control_cnt <= din_valid ? control_cnt + 4'd1 : control_cnt;
	else
		control_cnt <= 4'd0;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		dis_width <= 16'd0;
		dis_height <= 16'd0;
		dis_interlaced <= 4'd0;
	end
	else if(state==CTRL && din_valid)
	begin
		case(COLOR_PLANES)
		1:begin
			case(control_cnt)
			4'd0:dis_width[15:12] <= din_data[3:0];
			4'd1:dis_width[11:8] <= din_data[3:0];
			4'd2:dis_width[7:4] <= din_data[3:0];
			4'd3:dis_width[3:0] <= din_data[3:0];
			4'd4:dis_height[15:12] <= din_data[3:0];
			4'd5:dis_height[11:8] <= din_data[3:0];
			4'd6:dis_height[7:4] <= din_data[3:0];
			4'd7:dis_height[3:0] <= din_data[3:0];
			4'd8:dis_interlaced <= din_data[3:0];
			endcase
		end
		2:begin
			case(control_cnt)
			4'd0:dis_width[15:8] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd1:dis_width[7:0] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd2:dis_height[15:8] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd3:dis_height[7:0] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd4:dis_interlaced <= din_data[3:0];
			endcase
		end
		3:begin
			case(control_cnt)
			4'd0:dis_width[15:4] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS],din_data[COLOR_BITS*2+3:COLOR_BITS*2]};
			4'd1:{dis_width[3:0],dis_height[15:8]} <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS],din_data[COLOR_BITS*2+3:COLOR_BITS*2]};
			4'd2:{dis_height[7:0],dis_interlaced} <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS],din_data[COLOR_BITS*2+3:COLOR_BITS*2]};
			endcase
		end
		endcase
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		dis_cnt_x <= 16'd0;
		dis_cnt_y <= 16'd0;
	end
	else if(state==DATA)
	begin
		if(din_valid)
		begin
			if(din_endofpacket)
			begin
				dis_cnt_x <= 16'd0;
				dis_cnt_y <= 16'd0;
			end
			else if((dis_cnt_x+16'd1)>=dis_width)
			begin
				dis_cnt_x <= 16'd0;
				dis_cnt_y <= dis_cnt_y+16'd1;
			end
			else
			begin
				dis_cnt_x <= (dis_cnt_x+16'd1);
				dis_cnt_y <= dis_cnt_y;
			end
		end
	end
	else
	begin
		dis_cnt_x <= 16'd0;
		dis_cnt_y <= 16'd0;
	end
end

endmodule
