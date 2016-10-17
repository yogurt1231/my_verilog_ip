module blind_pixel_decode(
	clk,rst_n,
	din_data,din_valid,din_ready,
	din_startofpacket,din_endofpacket,

	im_width,im_height,
	im_interlaced,
	
	dout_data,dout_valid,dout_ready,
	dout_startofpacket,dout_endofpacket
);

parameter						DATA_WIDTH		= 24;
parameter						COLOR_BITS		= 8;
parameter						COLOR_PLANES	= 3;

input								clk,rst_n;

input		[DATA_WIDTH-1:0]	din_data;
input								din_valid;
input								din_startofpacket,din_endofpacket;
output							din_ready;

output	[DATA_WIDTH-1:0]	dout_data;
output							dout_valid;
output							dout_startofpacket,dout_endofpacket;
input								dout_ready;

output	[15:0]				im_width,im_height;
output	[3:0]					im_interlaced;

reg	[15:0]	im_width,im_height;
reg	[3:0]		im_interlaced;
reg				dout_startofpacket_reg;

reg	[2:0]		state,n_state;
reg	[3:0]		head_cnt;
reg 				din_ready_reg;
wire				global_rst_n;

localparam	IDLE = 3'b001;
localparam	HEAD = 3'b010;
localparam	DATA = 3'b100;

assign dout_data				= din_data;
assign dout_valid				= state==DATA && din_valid;
assign dout_startofpacket	= dout_startofpacket_reg & din_valid;
assign dout_endofpacket		= state==DATA && din_endofpacket;
assign din_ready				= din_ready_reg | dout_ready;

always @(state or n_state)
begin
	case(state)
	IDLE: din_ready_reg = n_state!=DATA;
	HEAD: din_ready_reg = 1'b1;
	DATA: din_ready_reg = 1'b0;
	default: din_ready_reg = 1'b1;
	endcase
end

always @(posedge clk or negedge global_rst_n)
begin
	if(!global_rst_n)
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
			4'hF:n_state = HEAD;
			3'h0:n_state = DATA;
			default:n_state = IDLE;
			endcase
		end
		else
			n_state = IDLE;
	end
	HEAD,DATA:n_state = (din_valid & din_endofpacket) ? IDLE : state;
	default:n_state = IDLE;
	endcase
end

always @(posedge clk or negedge global_rst_n)
begin
	if(!global_rst_n)
		dout_startofpacket_reg <= 1'b0;
	else if(state==IDLE && n_state==DATA)
		dout_startofpacket_reg <= 1'b1;
	else if(dout_startofpacket)
		dout_startofpacket_reg <= 1'b0;
end

always @(posedge clk or negedge global_rst_n)
begin
	if(!global_rst_n)
		head_cnt <= 4'd0;
	else if(state==HEAD)
		head_cnt <= din_valid ? head_cnt + 4'd1 : head_cnt;
	else
		head_cnt <= 4'd0;
end

always @(posedge clk or negedge global_rst_n)
begin
	if(!global_rst_n)
	begin
		im_width <= 16'd0;
		im_height <= 16'd0;
		im_interlaced <= 4'd0;
	end
	else if(state==HEAD && din_valid)
	begin
		case(COLOR_PLANES)
		1:begin
			case(head_cnt)
			4'd0:im_width[15:12] <= din_data[3:0];
			4'd1:im_width[11:8] <= din_data[3:0];
			4'd2:im_width[7:4] <= din_data[3:0];
			4'd3:im_width[3:0] <= din_data[3:0];
			4'd4:im_height[15:12] <= din_data[3:0];
			4'd5:im_height[11:8] <= din_data[3:0];
			4'd6:im_height[7:4] <= din_data[3:0];
			4'd7:im_height[3:0] <= din_data[3:0];
			4'd8:im_interlaced <= din_data[3:0];
			endcase
		end
		2:begin
			case(head_cnt)
			4'd0:im_width[15:8] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd1:im_width[7:0] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd2:im_height[15:8] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd3:im_height[7:0] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS]};
			4'd4:im_interlaced <= din_data[3:0];
			endcase
		end
		3:begin
			case(head_cnt)
			4'd0:im_width[15:4] <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS],din_data[COLOR_BITS*2+3:COLOR_BITS*2]};
			4'd1:{im_width[3:0],im_height[15:8]} <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS],din_data[COLOR_BITS*2+3:COLOR_BITS*2]};
			4'd2:{im_height[7:0],im_interlaced} <= {din_data[3:0],din_data[COLOR_BITS+3:COLOR_BITS],din_data[COLOR_BITS*2+3:COLOR_BITS*2]};
			endcase
		end
		endcase
	end
end

assign global_rst_n = rst_n;

endmodule
