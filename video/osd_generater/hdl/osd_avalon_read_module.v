module osd_avalon_read_module(
	clk,
	rst_n,
	
	frame_addr,
	frame_num,
	
	am_address,
	am_read,
	am_readdata,
	am_readdatavalid,
	am_byteenable,
	am_waitrequest,
	
	dout_data,
	dout_valid,
	dout_ready,
	dout_startofpacket,
	dout_endofpacket
);

parameter		DATA_LOG			= 3;

localparam		ADDRESS_ADD		= {{(34-DATA_LOG){1'b0}}, 1'b1, {(DATA_LOG-3){1'b0}}};
localparam		ADDRESS_MASK	= {{(35-DATA_LOG){1'b1}}, {(DATA_LOG-3){1'b0}}};
localparam		BYTE_ENA_MSAK	= {{(35-DATA_LOG){1'b0}}, {(DATA_LOG-3){1'b1}}};

input 			clk, rst_n;

input	[31:0]	frame_addr;
input [31:0]	frame_num;

output [31:0]							am_address;
output reg								am_read;
input [(1<<DATA_LOG)-1:0]			am_readdata;
input 									am_readdatavalid;
input 									am_waitrequest;
output [(1<<(DATA_LOG-3))-1:0]	am_byteenable;

output 	dout_data;
output 	dout_valid;
input		dout_ready;
output 	dout_startofpacket;
output 	dout_endofpacket;

reg [31:0]	f_num, addr_reg;
reg [31:0]	dout_addr, dout_cnt;
reg [1:0]	state, n_state;

reg [DATA_LOG-1:0]				pixel_cnt;
wire [DATA_LOG-1:0]				addr_byte;
wire [(1<<(DATA_LOG-3))-1:0]	byte_mask;
reg [(1<<DATA_LOG)-1:0]			readdata_reg;

localparam	IDLE	= 2'd0;
localparam	READ	= 2'd1;
localparam	WAIT	= 2'd2;
localparam	DOUT	= 2'd3;

assign am_address				= dout_addr;
assign dout_data				= readdata_reg[pixel_cnt];
assign dout_valid				= state == DOUT;
assign dout_startofpacket	= state == DOUT && dout_cnt == f_num;
assign dout_endofpacket		= state == DOUT && dout_cnt == 32'd1;
assign am_byteenable			= state==READ && dout_cnt==f_num ? byte_mask<<addr_byte : byte_mask;

assign addr_byte				= addr_reg & BYTE_ENA_MSAK;
assign byte_mask				= {(1<<(DATA_LOG-3)){1'b1}};

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or dout_ready or am_readdatavalid or dout_cnt or pixel_cnt)
begin
	case (state)
	IDLE: n_state = dout_cnt != 32'd0 ? READ : IDLE;
	READ:	n_state = am_readdatavalid ? WAIT : READ;
	WAIT: n_state = dout_ready ? DOUT : WAIT;
	DOUT: begin
		if (dout_cnt == 32'd1)
			n_state = IDLE;
		else if(pixel_cnt == {DATA_LOG{1'b1}})
			n_state = READ;
		else
			n_state = DOUT;
	end
	default: n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		readdata_reg <= {(1<<DATA_LOG){1'b0}};
	else if (am_readdatavalid)
		readdata_reg <= am_readdata;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		{addr_reg, f_num} <= {32'd0, 32'd0};
	else if (state == IDLE)
		{addr_reg, f_num} <= {frame_addr, frame_num};
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		dout_addr <= 32'd0;
	else if (state == IDLE)
		dout_addr <= addr_reg & ADDRESS_MASK;
	else if (am_readdatavalid)
		dout_addr <= dout_addr + ADDRESS_ADD;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		dout_cnt <= 32'd0;
	else if (state == IDLE)
		dout_cnt <= frame_num;
	else if (dout_valid)
		dout_cnt <= dout_cnt - 32'd1;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		pixel_cnt <= {DATA_LOG{1'b0}};
	else if (state == READ)
		pixel_cnt <= dout_cnt==f_num ? addr_byte[DATA_LOG-1:0]<<3 : {DATA_LOG{1'b0}};
	else if (state == DOUT)
		pixel_cnt <= pixel_cnt + 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		am_read <= 1'b0;
	else if (state != READ && n_state == READ)
		am_read <= 1'b1;
	else if (am_read & ~am_waitrequest)
		am_read <= 1'b0;
end

endmodule
