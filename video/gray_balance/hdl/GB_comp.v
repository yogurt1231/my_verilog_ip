module GB_comp(
	clk,rst_n,
	
	aft_valid,aft_endofpacket,
	
	gray_ram_read_addr,gray_ram_read_q,
	gray_ram_write_addr,gray_ram_write,
	
	map_ram_write_addr,map_ram_write_data,
	map_ram_write,
	
	div_numer,div_demon_shift,div_quotient,
	
	state_comp
);

parameter	DIN_WIDTH = 14;
parameter	DOUT_WIDTH = 10;

parameter	WRITE_LATENCY = 2;

input								clk,rst_n;
input								aft_valid,aft_endofpacket;
input								gray_ram_read_q;
output	[DIN_WIDTH-1:0]	gray_ram_read_addr;
output	[DIN_WIDTH-1:0]	gray_ram_write_addr;
output							gray_ram_write;
output	[DIN_WIDTH-1:0]	map_ram_write_addr;
output	[DOUT_WIDTH-1:0]	map_ram_write_data;
output							map_ram_write;
output	[DIN_WIDTH+DOUT_WIDTH:0]	div_numer;
input		[DOUT_WIDTH-1:0]	div_quotient;
input		[DIN_WIDTH-1:0]	div_demon_shift;
output							state_comp;

reg	[DIN_WIDTH:0]		gray_num;
reg	[DIN_WIDTH-1:0]	cnt_read,cnt_write;
wire	[DIN_WIDTH-1:0]	cnt_read_add,cnt_write_add;
wire	[DIN_WIDTH+DOUT_WIDTH:0] div_numer_reg;

reg	[3:0]	state,n_state;

localparam	IDLE = 4'b0001;
localparam	READ = 4'b0010;
localparam	WAIT = 4'b0100;
localparam	WRITE = 4'b1000;

assign cnt_read_add = cnt_read + 'd1;
assign cnt_write_add = cnt_write + 'd1;

assign gray_ram_read_addr = cnt_read;
assign gray_ram_write_addr = cnt_write;
assign map_ram_write_addr = cnt_write;
assign map_ram_write_data = div_quotient;

assign div_numer_reg[DOUT_WIDTH-1:0] = 'd0;
assign div_numer_reg[DIN_WIDTH+DOUT_WIDTH:DOUT_WIDTH] = gray_num;
assign div_numer = div_numer_reg-gray_num+div_demon_shift;

assign state_comp = state!=IDLE;
assign map_ram_write = state==WRITE;
assign gray_ram_write = state==WRITE;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= n_state;
end

always @(state or aft_valid or aft_endofpacket or cnt_read_add or cnt_write_add)
begin
	case(state)
	IDLE:n_state = (aft_valid & aft_endofpacket) ? READ : IDLE;
	READ:n_state = (cnt_read_add=='d2) ? WAIT : READ;
	WAIT:n_state = (cnt_read_add==WRITE_LATENCY) ? WRITE : WAIT;
	WRITE:n_state = (cnt_write_add=='d0) ? IDLE : WRITE;
	default:n_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt_read <= 'd0;
	else if(state!=IDLE)
		cnt_read <= cnt_read_add;
	else
		cnt_read <= 'd0;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cnt_write <= 'd0;
	else if(state==WRITE)
		cnt_write <= cnt_write_add;
	else
		cnt_write <= 'd0;
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		gray_num <= 'd0;
	else if(state==IDLE || state==READ)
		gray_num <= 'd0;
	else if(gray_ram_read_q)
		gray_num <= gray_num + 'd1;
end

endmodule
