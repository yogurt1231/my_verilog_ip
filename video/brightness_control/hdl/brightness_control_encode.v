module brightness_control_encode(
	clk,rst_n,

	video_width,video_height,video_interlaced,

	din_data,din_valid,din_ready,
	din_startofpacket,din_endofpacket,

	dout_data,dout_valid,dout_ready,
	dout_startofpacket,dout_endofpacket
);

parameter						DATA_WIDTH	= 8;
parameter						DATA_BITS	= 8;
parameter						DATA_PLANES	= 1;

input								clk,rst_n;

input		[15:0]				video_width,video_height;
input		[3:0]					video_interlaced;

input		[DATA_WIDTH-1:0]	din_data;
input								din_valid,din_startofpacket,din_endofpacket;
output							din_ready;

output	[DATA_WIDTH-1:0]	dout_data;
output							dout_valid,dout_startofpacket,dout_endofpacket;
input								dout_ready;

reg		[2:0]					state,n_state;
reg		[3:0]					cnt;
reg		[DATA_WIDTH-1:0]	dout_data_reg;
reg								dout_ready_reg;

reg		[15:0]				width,height;
reg		[3:0]					interlaced;
wire		[DATA_BITS-1:0]	ctrl_pack[9];

localparam IDLE = 3'b001;
localparam CODE = 3'b010;
localparam DATA = 3'b100;

assign din_ready				= (n_state!=CODE) && dout_ready;
assign dout_valid				= ((state==DATA) && din_valid)	|| ((state==CODE) && dout_ready_reg);
assign dout_startofpacket	= (cnt==4'd1)							|| ((DATA_PLANES==1)&&(cnt==4'hB)) || ((DATA_PLANES==2)&&(cnt==4'h7)) || ((DATA_PLANES==3)&&(cnt==4'h5));
assign dout_endofpacket		= (din_endofpacket & din_valid)	|| ((DATA_PLANES==1)&&(cnt==4'hA)) || ((DATA_PLANES==2)&&(cnt==4'h6)) || ((DATA_PLANES==3)&&(cnt==4'h4));
assign dout_data				= dout_data_reg;

assign ctrl_pack[0] = width[15:12];
assign ctrl_pack[1] = width[11:8];
assign ctrl_pack[2] = width[7:4];
assign ctrl_pack[3] = width[3:0];
assign ctrl_pack[4] = height[15:12];
assign ctrl_pack[5] = height[11:8];
assign ctrl_pack[6] = height[7:4];
assign ctrl_pack[7] = height[3:0];
assign ctrl_pack[8] = interlaced;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		width <= 16'd0;
		height <= 16'd0;
		interlaced <= 4'd0;
	end
	else if(state==IDLE && n_state==CODE)
	begin
		width <= video_width;
		height <= video_height;
		interlaced <= video_interlaced;
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or cnt or din_startofpacket or din_endofpacket or din_valid or dout_ready_reg)
begin
	case(state)
	IDLE:n_state = (din_startofpacket & din_valid) ? CODE : IDLE;
	CODE:begin
		case(DATA_PLANES)
		1:n_state = ((cnt==4'hC) && dout_ready_reg) ? DATA : CODE;
		2:n_state = ((cnt==4'h8) && dout_ready_reg) ? DATA : CODE;
		3:n_state = ((cnt==4'h6) && dout_ready_reg) ? DATA : CODE;
		endcase
	end
	DATA:n_state = (din_endofpacket & din_valid) ? IDLE : DATA;
	default:n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		dout_ready_reg <= 1'b0;
	else
		dout_ready_reg <= dout_ready;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt <= 4'd0;
	else if(n_state==CODE)
		cnt <= dout_ready_reg ? (cnt + 4'd1) : cnt;
	else
		cnt <= 4'd0;
end

always @(state or cnt or din_data)
begin
	if(state==CODE)
	begin
		case(DATA_PLANES)
		1:begin
			case(cnt)
			4'h1:dout_data_reg = 'hF;
			4'h2:dout_data_reg = ctrl_pack[0];
			4'h3:dout_data_reg = ctrl_pack[1];
			4'h4:dout_data_reg = ctrl_pack[2];
			4'h5:dout_data_reg = ctrl_pack[3];
			4'h6:dout_data_reg = ctrl_pack[4];
			4'h7:dout_data_reg = ctrl_pack[5];
			4'h8:dout_data_reg = ctrl_pack[6];
			4'h9:dout_data_reg = ctrl_pack[7];
			4'hA:dout_data_reg = ctrl_pack[8];
			4'hB:dout_data_reg = 'h0;
			4'hC:dout_data_reg = din_data;
			default:dout_data_reg = din_data;
			endcase
		end
		2:begin
			case(cnt)
			4'h1:dout_data_reg = 'hF;
			4'h2:dout_data_reg = {ctrl_pack[1],ctrl_pack[0]};
			4'h3:dout_data_reg = {ctrl_pack[3],ctrl_pack[2]};
			4'h4:dout_data_reg = {ctrl_pack[5],ctrl_pack[4]};
			4'h5:dout_data_reg = {ctrl_pack[7],ctrl_pack[6]};
			4'h6:dout_data_reg = ctrl_pack[8];
			4'h7:dout_data_reg = 'h0;
			4'h8:dout_data_reg = din_data;
			default:dout_data_reg = din_data;
			endcase
		end
		3:begin
			case(cnt)
			4'h1:dout_data_reg = 'hF;
			4'h2:dout_data_reg = {ctrl_pack[2],ctrl_pack[1],ctrl_pack[0]};
			4'h3:dout_data_reg = {ctrl_pack[5],ctrl_pack[4],ctrl_pack[3]};
			4'h4:dout_data_reg = {ctrl_pack[8],ctrl_pack[7],ctrl_pack[6]};
			4'h5:dout_data_reg = 'h0;
			4'h6:dout_data_reg = din_data;
			default:dout_data_reg = din_data;
			endcase
		end
		default:dout_data_reg = din_data;
		endcase
	end
	else
		dout_data_reg = din_data;
end

endmodule
